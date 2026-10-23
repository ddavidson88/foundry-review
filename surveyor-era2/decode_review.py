"""Decode and verify the adjacent review bundle using Python standard library."""
from pathlib import Path
import base64, hashlib
root = Path(__file__).resolve().parent
data = base64.b64decode((root / "Surveyor-0.1.0-era.2-REVIEW.zip.base64").read_text().strip(), validate=True)
assert len(data) == 403513, "Review bundle length mismatch"
assert hashlib.sha256(data).hexdigest() == "8f787db20ed91f2ef0fa324ca8950ca511035efc560e76b59b6fd2ad7445b191", "Review bundle hash mismatch"
out = root / "Surveyor-0.1.0-era.2-REVIEW.zip"
out.write_bytes(data)
print("Verified:", out)
