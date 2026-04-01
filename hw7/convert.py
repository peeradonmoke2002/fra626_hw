from PIL import Image
import os

input_folder = r"C:\Development\fra626_hw\hw7\case7_images_bmp"
output_folder = r"C:\Development\fra626_hw\hw7\case7_images_resized"

os.makedirs(output_folder, exist_ok=True)

for filename in os.listdir(input_folder):
    if filename.endswith(".bmp"):
        img = Image.open(os.path.join(input_folder, filename))
        img_resized = img.resize((480, 640))  # portrait orientation
        img_resized.save(os.path.join(output_folder, filename))
        print(f"Resized: {filename}")