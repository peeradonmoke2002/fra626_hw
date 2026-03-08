
clear; clc; close all;


datasetPath = fullfile(fileparts(mfilename('fullpath')), '..', 'dataset');
imgSize     = [227 227 3];   % SqueezeNet input size
numEpochs   = 10;
miniBatch   = 32;
learnRate   = 1e-4;


fprintf('=== Loading Dataset ===\n');
imds = imageDatastore(datasetPath, ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

% Keep only bird / cat / dog labels
validLabels = {'bird', 'cat', 'dog'};
mask = ismember(string(imds.Labels), validLabels);
imds = subset(imds, mask);

labelCounts = countEachLabel(imds);
disp(labelCounts);

classNames = categories(imds.Labels);
numClasses = numel(classNames);

% Balance classes (cap at min class count)
minCount = min(labelCounts.Count);
[imds, ~] = splitEachLabel(imds, minCount, 'randomized');
fprintf('Balanced to %d images per class (%d total)\n\n', minCount, numel(imds.Files));

% Train / Validation split: 80 / 20
[imdsTrain, imdsVal] = splitEachLabel(imds, 0.8, 'randomized');
fprintf('Train: %d | Val: %d\n\n', numel(imdsTrain.Files), numel(imdsVal.Files));


augTrain = augmentedImageDatastore(imgSize, imdsTrain, ...
    'DataAugmentation', imageDataAugmenter( ...
        'RandXReflection', true, ...
        'RandRotation',    [-15, 15], ...
        'RandXTranslation', [-10, 10], ...
        'RandYTranslation', [-10, 10]));

augVal = augmentedImageDatastore(imgSize, imdsVal);


fprintf('=== Part C: Transfer Learning (SqueezeNet) ===\n');

% Load pretrained SqueezeNet
net = squeezenet;

% Inspect the network
fprintf('SqueezeNet has %d layers.\n', numel(net.Layers));
disp(net.Layers(end-2:end));

lgraph = layerGraph(net);

newConv = convolution2dLayer(1, numClasses, ...
    'WeightLearnRateFactor', 10, ...
    'BiasLearnRateFactor',   10, ...
    'Name', 'new_conv');

lgraph = replaceLayer(lgraph, 'conv10', newConv);

newOutput = classificationLayer('Name', 'new_classoutput', ...
    'Classes', classNames);
lgraph = replaceLayer(lgraph, 'ClassificationLayer_predictions', newOutput);

fprintf('Network modified for %d classes: %s\n\n', numClasses, strjoin(classNames, ', '));


parallel.gpu.enableCUDAForwardCompatibility(true);

opts = trainingOptions('adam', ...
    'InitialLearnRate',    learnRate, ...
    'MaxEpochs',           numEpochs, ...
    'MiniBatchSize',       miniBatch, ...
    'ValidationData',      augVal, ...
    'ValidationFrequency', 30, ...
    'ExecutionEnvironment','gpu', ...
    'Plots',               'training-progress', ...
    'Verbose',             true);

fprintf('Training Transfer Learning model...\n');
tic;
netTransfer = trainNetwork(augTrain, lgraph, opts);
trainTime = toc;
fprintf('Training complete in %.1f seconds.\n\n', trainTime);

modelPath = fullfile(fileparts(mfilename('fullpath')), 'squeezenet_bird_cat_dog.mat');
save(modelPath, 'netTransfer', 'classNames');
fprintf('Model saved to: %s\n\n', modelPath);


fprintf('=== Evaluating Transfer Learning Model ===\n');

% Classify validation set
[predLabels, scores] = classify(netTransfer, augVal);
trueLabels = imdsVal.Labels;

% Accuracy
transferAcc = mean(predLabels == trueLabels) * 100;
fprintf('Transfer Learning Validation Accuracy: %.2f%%\n\n', transferAcc);

% Confusion Matrix
figure('Name', 'Transfer Learning - Confusion Matrix');
confusionchart(trueLabels, predLabels, ...
    'Title', sprintf('SqueezeNet Transfer Learning\nVal Accuracy: %.1f%%', transferAcc), ...
    'RowSummary',    'row-normalized', ...
    'ColumnSummary', 'column-normalized');


figure('Name', 'Sample Predictions');
numShow = 9;
idx = randperm(numel(imdsVal.Files), numShow);

for k = 1:numShow
    img = readimage(imdsVal, idx(k));
    trueLabel = trueLabels(idx(k));
    predLabel = predLabels(idx(k));
    conf      = max(scores(idx(k), :)) * 100;

    subplot(3, 3, k);
    imshow(imresize(img, [100 100]));

    color = 'green';
    if predLabel ~= trueLabel
        color = 'red';
    end
    title(sprintf('True: %s\nPred: %s (%.0f%%)', ...
        char(trueLabel), char(predLabel), conf), ...
        'Color', color, 'FontSize', 8);
end
sgtitle('Sample Predictions (Green=Correct, Red=Wrong)');


fprintf('\n=== ML vs Deep Learning Summary ===\n');
fprintf('---------------------------------------------\n');
fprintf('%-30s %-20s %-20s\n', 'Aspect', 'ANN (Part 1)', 'CNN (Part 2)');
fprintf('---------------------------------------------\n');
fprintf('%-30s %-20s %-20s\n', 'Feature extraction', 'Manual (HOG)', 'Automatic (learned)');
fprintf('%-30s %-20s %-20s\n', 'Data needed',       'Small-medium',  'Large (or pretrained)');
fprintf('%-30s %-20s %-20s\n', 'Training speed',    'Fast',          'Slower (GPU helps)');
fprintf('%-30s %-20s %-20s\n', 'Spatial structure', 'Ignored',       'Preserved');
fprintf('%-30s %-20s %-20s\n', 'Accuracy (images)', 'Moderate',      'High (with transfer)');
fprintf('---------------------------------------------\n');
fprintf('\nTransfer Learning Accuracy: %.2f%%\n', transferAcc);
fprintf('\nPart 2 complete!\n');
