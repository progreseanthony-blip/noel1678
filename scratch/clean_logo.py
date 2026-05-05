from PIL import Image

def clean_logo():
    path = r"c:\Fred\Programas\Golf 2\apps\main_app\assets\images\global_golf_logo.png"
    img = Image.open(path).convert("RGBA")
    
    # Load pixels
    pixels = img.load()
    width, height = img.size
    
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            
            # Find max and min RGB values to determine if the pixel is grayscale-ish
            max_rgb = max(r, g, b)
            min_rgb = min(r, g, b)
            
            # The fake transparency grid is white and light grey.
            # If color difference is small (it's grey/white) and it's light enough (r > 150)
            if (max_rgb - min_rgb < 40) and r > 150:
                pixels[x, y] = (r, g, b, 0)
                
    img.save(path)
    print("Logo cleaned successfully!")

if __name__ == "__main__":
    clean_logo()
