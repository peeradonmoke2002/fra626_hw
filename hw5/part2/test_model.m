%% Test the trained SqueezeNet model on new images
% Usage:
%   1. Run this script to test on random validation images
%   2. Change testImagePath to classify YOUR OWN image

clear; clc; close all;

hwDir     = fileparts(mfilename('fullpath'));
modelPath = fullfile(hwDir, 'squeezenet_bird_cat_dog.mat');
datasetPath = fullfile(hwDir, '..', 'dataset');

%% =========================================================
%  1. Load Saved Model
% =========================================================
if ~isfile(modelPath)
    error('Model not found. Please run part2_deep_learning_cnn.m first to train and save the model.');
end

fprintf('Loading model...\n');
load(modelPath, 'netTransfer', 'classNames');
fprintf('Model loaded. Classes: %s\n\n', strjoin(classNames, ', '));

%% =========================================================
%  2. OPTION A — Test on a single custom image
%     Change this path to your own image file
% =========================================================
testImagePath = '';   % <-- put your image path here, e.g. '/home/.../mybird.jpg'

if ~isempty(testImagePath) && isfile(testImagePath)
    fprintf('--- Testing custom image ---\n');
    img = imread(testImagePath);
    img = imresize(img, [227 227]);

    parallel.gpu.enableCUDAForwardCompatibility(true);
    [label, scores] = classify(netTransfer, img);
    confidence = max(scores) * 100;

    figure('Name', 'Custom Image Test');
    imshow(img);
    title(sprintf('Prediction: %s  (%.1f%% confidence)', char(label), confidence), ...
        'FontSize', 14, 'FontWeight', 'bold');
    fprintf('Result: %s (%.1f%%)\n\n', char(label), confidence);
end

%% =========================================================
%  3. OPTION B — Test on random images from dataset
% =========================================================
fprintf('--- Testing on random dataset images ---\n');

imds = imageDatastore(datasetPath, ...
    'IncludeSubfolders', true, ...
    'LabelSource',       'foldernames');

validLabels = {'bird', 'cat', 'dog'};
mask = ismember(string(imds.Labels), validLabels);
imds = subset(imds, mask);

% Pick 9 random images
numTest = 9;
idx     = randperm(numel(imds.Files), numTest);

augTest = augmentedImageDatastore([227 227 3], subset(imds, idx));

parallel.gpu.enableCUDAForwardCompatibility(true);
[predLabels, scores] = classify(netTransfer, augTest);
trueLabels = imds.Labels(idx);

% Display results
correct = 0;
figure('Name', 'Test Results', 'Position', [100 100 900 900]);

for k = 1:numTest
    img  = readimage(imds, idx(k));
    pred = char(predLabels(k));
    tru  = char(trueLabels(k));
    conf = max(scores(k,:)) * 100;

    isCorrect = strcmp(pred, tru);
    if isCorrect, correct = correct + 1; end

    subplot(3, 3, k);
    imshow(imresize(img, [150 150]));
    color = 'green';
    if ~isCorrect, color = 'red'; end
    title(sprintf('True: %s\nPred: %s  %.1f%%', tru, pred, conf), ...
        'Color', color, 'FontSize', 8);
end

acc = correct / numTest * 100;
sgtitle(sprintf('Test Results  |  %d/%d correct (%.0f%%)  |  Green=Correct  Red=Wrong', ...
    correct, numTest, acc), 'FontSize', 11);

fprintf('Accuracy on %d random test images: %d/%d (%.0f%%)\n', numTest, correct, numTest, acc);
