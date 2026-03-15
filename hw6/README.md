# Case Study #6: Can Alignment Inspection
NI Vision Builder for Automated Inspection (VBAI)
FRA 626 Machine Vision in Smart Factory

## Objective
Inspect the alignment of stacked cat food cans using pattern matching.
Detect whether the top can label is correctly aligned or misaligned.

## Inspection Steps
1. Read Image File - Load images from folder
2. Vision Assistant - Convert RGB to Grayscale
3. Match Pattern - Locate bottom can as reference
4. Set Coordinate System - Set reference coordinate
5. Match Pattern - Check top can alignment
6. Set Inspection Status - Set PASS/FAIL
7. Custom Overlay - Show "ALIGNED" (green) or "MISALIGNED!" (red)

## Results
| Image   | Original Image | Top Can Status        | Result | Output Image |
|---------|----------------|-----------------------|--------|--------------|
| photo01 | ![](case6_images_original/photo01_result.png) | Cat face front        | PASS   | ![](case6_images_results/Pass1.png) |
| photo02 | ![](case6_images_original/photo02_result.png) | Barcode visible       | FAIL   | ![](case6_images_results/fail1.png) |
| photo03 | ![](case6_images_original/photo03_result.png) | Bottom of can visible | FAIL   | ![](case6_images_results/fail2.png) |
| photo04 | ![](case6_images_original/photo04_result.png) | Bottom of can visible | FAIL   | ![](case6_images_results/fail3.png) |
| photo05 | ![](case6_images_original/photo05_result.png) | Barcode visible       | FAIL   | ![](case6_images_results/fail4.png) |
| photo06 | ![](case6_images_original/photo06_result.png) | Bottom of can visible | FAIL   | ![](case6_images_results/fail5.png) |

## Tools Used
- NI Vision Builder AI 2023 Q3 (64-bit)
- Match Pattern
- Vision Assistant
- Custom Overlay