from fastapi import FastAPI
from pydantic import BaseModel
import subprocess

app = FastAPI()

class RunRequest(BaseModel):
    url: str
    name: str

@app.post("/run")
def run_pipeline(req: RunRequest):
    result = subprocess.run(
        ["/app/bbb_to_audio.sh", req.url, req.name],
        capture_output=True,
        text=True
    )

    return {
        "stderr": result.stderr,
        "code": result.returncode
    }