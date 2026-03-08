
clear; clc; close all;

datasetPath = fullfile(fileparts(mfilename('fullpath')), '..', 'dataset');
classes     = {'bird', 'cat', 'dog'};
numPerClass = 1000;
imgSize     = [64 64];

fprintf('=== Phase 1: Extracting Features ===\n');

% Get feature sizes from sample image
sampleFiles = dir(fullfile(datasetPath, classes{1}, classes{1}, '*.jpg'));
sampleImg   = imresize(imread(fullfile(datasetPath, classes{1}, classes{1}, sampleFiles(1).name)), imgSize);
if size(sampleImg,3)==1, sampleImg=repmat(sampleImg,[1 1 3]); end
hogSize  = numel(extractHOGFeatures(rgb2gray(sampleImg), 'CellSize', [8 8]));
lbpSize  = numel(extractLBPFeatures(rgb2gray(sampleImg)));
numFeatures = hogSize + 96 + lbpSize;   % HOG + Color(32x3) + LBP
fprintf('Features: HOG(%d) + Color(96) + LBP(%d) = %d total\n', hogSize, lbpSize, numFeatures);

n      = numPerClass * numel(classes);
X_raw  = zeros(n, numFeatures);
labels = zeros(n, 1);

for c = 1:numel(classes)
    classDir = fullfile(datasetPath, classes{c}, classes{c});
    files    = dir(fullfile(classDir, '*.jpg'));
    idx      = randperm(numel(files), numPerClass);
    for k = 1:numPerClass
        img = imread(fullfile(classDir, files(idx(k)).name));
        img = imresize(img, imgSize);
        if size(img,3)==1, img=repmat(img,[1 1 3]); end

        hog = extractHOGFeatures(rgb2gray(img), 'CellSize', [8 8]);
        hsv = rgb2hsv(img);
        hH  = histcounts(hsv(:,:,1), 32, 'Normalization', 'probability');
        hS  = histcounts(hsv(:,:,2), 32, 'Normalization', 'probability');
        hV  = histcounts(hsv(:,:,3), 32, 'Normalization', 'probability');
        lbp = extractLBPFeatures(rgb2gray(img));

        X_raw((c-1)*numPerClass+k, :) = [hog, hH, hS, hV, lbp];
        labels((c-1)*numPerClass+k)   = c;
    end
    fprintf('  Loaded: %s\n', classes{c});
end

% Normalize + format for MATLAB ANN
[X_norm, ~, ~] = zscore(X_raw);
X = X_norm';           % (features x samples)
T = dummyvar(labels)'; % (classes  x samples)

cv     = cvpartition(labels, 'Holdout', 1/3);
Xtrain = X(:, cv.training);   Ttrain = T(:, cv.training);
Xtest  = X(:, cv.test);       Ytest  = labels(cv.test);

fprintf('\nTrain: %d | Test: %d\n', sum(cv.training), sum(cv.test));
fprintf('Xtrain: [%dx%d] | Ttrain: [%dx%d]\n\n', size(Xtrain,1), size(Xtrain,2), size(Ttrain,1), size(Ttrain,2));

fprintf('=== Phase 2: nnstart GUI ===\n');
fprintf('  1. Click "Pattern Recognition" (nprtool)\n');
fprintf('  2. Predictors: Xtrain | Responses: Ttrain | Observations: Columns\n');
fprintf('  3. Layer size: 100 -> Train\n');
fprintf('  4. View Confusion Matrix & ROC Curve\n');
fprintf('  5. Export Model -> Export to Workspace\n\n');

nnstart;
input('Press Enter after exporting net from nnstart to continue...\n');

if exist('net', 'var')
    pred = net(Xtest);
    [~, predLbl] = max(pred);
    acc = mean(Ytest' == predLbl) * 100;
    fprintf('\nnnstart Test Accuracy: %.2f%%\n\n', acc);

    figure('Name', 'nnstart — Confusion Matrix');
    confusionchart(classes(Ytest)', classes(predLbl)', ...
        'Title',         sprintf('ANN via nnstart | Test Acc: %.1f%%', acc), ...
        'RowSummary',    'row-normalized', ...
        'ColumnSummary', 'column-normalized');
end

fprintf('=== Phase 3: Neuron Sweep ===\n');
sweepSizes = [10 50 100 150 200 250 300];
sweepAcc   = zeros(size(sweepSizes));

for i = 1:numel(sweepSizes)
    h    = sweepSizes(i);
    netS = patternnet([h h/2], 'trainscg');
    netS.trainParam.epochs     = 300;
    netS.trainParam.showWindow = false;
    netS.divideParam.trainRatio = 0.70;
    netS.divideParam.valRatio   = 0.15;
    netS.divideParam.testRatio  = 0.15;
    netS = train(netS, Xtrain, Ttrain);
    [~, p] = max(netS(Xtest));
    sweepAcc(i) = mean(Ytest'==p) * 100;
    fprintf('  Neurons: %3d -> %.2f%%\n', h, sweepAcc(i));
end

[bestAcc, bestIdx] = max(sweepAcc);
fprintf('\nBest: %d neurons -> %.2f%%\n', sweepSizes(bestIdx), bestAcc);

figure('Name', 'Neuron Sweep');
plot(sweepSizes, sweepAcc, 'b-o', 'LineWidth', 2, 'MarkerFaceColor', 'b');
xlabel('Hidden Neurons'); ylabel('Test Accuracy (%)');
title('ANN: Hidden Neurons vs Accuracy (bird/cat/dog)');
grid on; ylim([0 100]);
xline(sweepSizes(bestIdx), '--r', sprintf('Best: %d neurons (%.1f%%)', sweepSizes(bestIdx), bestAcc), 'LineWidth', 1.5);
