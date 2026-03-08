# HW6: Neural Networks & Deep Learning in MATLAB

**Dataset:** Bird / Cat / Dog (~13,000 images, 3 classes)

---

## Structure

```
hw6/
├── dataset/
│   ├── bird/bird/*.jpg   (4,149 images)
│   ├── cat/cat/*.jpg     (4,015 images)
│   └── dog/dog/*.jpg     (5,180 images)
├── part1/
│   └── part1_ann.m       — ANN with HOG + Color + LBP features (nnstart GUI)
├── part2/
│   ├── part2_deep_learning_cnn.m  — Transfer Learning (SqueezeNet)
│   └── test_model.m               — Test trained model on new images
└── README.md
```

---

## Part 1 — Artificial Neural Network (ANN)

**Reference:** https://blogs.mathworks.com/loren/2015/08/04/artificial-neural-networks-for-beginners/

### Approach
- Feature extraction: **HOG + Color Histogram (HSV) + LBP** (1,919 features/image)
- Network: `patternnet` via **nnstart GUI**
- Training: Scaled Conjugate Gradient (`trainscg`)
- Data split: 67% train / 33% test

### How to Run
```matlab
cd hw6/part1
part1_ann
```

### Phases
| Phase | Description |
|-------|-------------|
| Phase 1 | Extract HOG + Color + LBP features from images |
| Phase 2 | Train via `nnstart` → Pattern Recognition GUI |
| Phase 3 | Neuron sweep 10→300, plot accuracy curve |

### Results

| Hidden Neurons | Test Accuracy |
|---------------|---------------|
| 10            | ~56%          |
| 50            | ~51%          |
| 100 (nnstart) | ~47%          |
| 200           | ~52%          |
| **Best**      | **~56%**      |

---

## Part 2 — Deep Learning (CNN Transfer Learning)

**Reference:** https://explore.mathworks.com/machine-learning-vs-deep-learning

### Approach
- Pretrained network: **SqueezeNet** (trained on ImageNet, 1000 classes)
- Fine-tuned final layer for 3 classes (bird/cat/dog)
- Optimizer: Adam, GPU accelerated (RTX 5070 Ti)
- Data augmentation: random flip, rotation ±15°, translation

### How to Run
```matlab
cd hw6/part2
part2_deep_learning_cnn   % train & save model
test_model                % test on random images
```

### Results

| Metric | Value |
|--------|-------|
| Dataset used | 4,015/class (12,045 total) |
| Train/Val split | 80% / 20% |
| Epochs | 10 |
| Validation Accuracy | **~94-95%** |
| Training time | ~16 min (GPU) |

---

## Performance Comparison

| Method | Features | Accuracy | Training Time |
|--------|----------|----------|---------------|
| ANN (Part 1) | HOG + Color + LBP (manual) | ~56% | Seconds |
| **CNN Transfer Learning (Part 2)** | Learned automatically | **~94%** | ~16 min |

## ML vs Deep Learning — Key Differences

| Aspect | ANN (Part 1) | CNN (Part 2) |
|--------|-------------|--------------|
| Feature extraction | Manual (HOG, LBP, Color) | Automatic (learned from data) |
| Spatial structure | Ignored (flat vector) | Preserved (convolutions) |
| Data required | Small–medium | Large (or pretrained) |
| Accuracy on images | Moderate (~56%) | High (~94%) |
| Training speed | Fast | Slower (GPU recommended) |
| Interpretability | Higher | Lower |
