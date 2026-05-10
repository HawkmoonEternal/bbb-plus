from fastapi import FastAPI
from pydantic import BaseModel
import subprocess

app = FastAPI()

class RunRequest(BaseModel):
    model: str
    name: str


@app.post("/run")
def run_pipeline(req: RunRequest):
    result = subprocess.run(
        ["/app/audio_to_transcript.sh", req.name, req.model],
        capture_output=True,
        text=True
    )

    return {
        "stderr": result.stderr,
        "code": result.returncode
    }