import fitz

try:
    doc = fitz.open("LOGO1.pdf")
    page = doc.load_page(0)
    # Use alpha=True to preserve transparency if available
    pix = page.get_pixmap(dpi=300, alpha=True)
    out_path = "CarRental.Web/public/retrix-logo.png"
    pix.save(out_path)
    print(f"Logo converted successfully to {out_path}!")
except Exception as e:
    print(f"Error converting logo: {e}")
