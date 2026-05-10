# /bin/bash
set -e

URL=""
MEETING_NAME="test"
PROVIDER="openai"
MODEL="gpt-4.1-mini"
WHISPER_MODEL="small.en"
API_KEY=""
CUSTOM_PROMT="Generate a summary of the meeting transcript."
CHUNK_SIZE=50000
OVERLAP=1000


while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)
      URL="$2"
      shift 2
      ;;
    --meeting-name)
      MEETING_NAME="$2"
      shift 2
      ;;
    --provider)
      PROVIDER="$2"
      shift 2
      ;;
    --model)
      MODEL="$2"
      shift 2
      ;;
    --whisper-model)
      WHISPER_MODEL="$2"
      shift 2
      ;;
    --api-key)
      API_KEY="$2"
      shift 2
      ;;
    --custom-prompt)
      CUSTOM_PROMPT="$2"
      shift 2
      ;;
    --chunk-size)
      CHUNK_SIZE=$2
      shift 2
      ;;
    --overlap)
      OVERLAP=$2
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Setup logs
DATE="$(date +%Y%m%d-%H%M%S)"
DOCKER_LOG=logs/$MEETING_NAME-$DATE/docker-$MEETING_NAME-$DATE.log
PIPELINE_LOG=logs/$MEETING_NAME-$DATE/pipeline-$MEETING_NAME-$DATE.log
mkdir -p logs/$MEETING_NAME-$DATE
touch $PIPELINE_LOG

echo ""
echo "*******************************************************************************************************************************"
if [ -f "transcript_to_summary/output/$MEETING_NAME.txt" ]; then
  echo "ERROR: Summary for $MEETING_NAME already exists. Run 'rm transcript_to_summary/output/$MEETING_NAME.txt' to delete it. Exit!" | tee -a $PIPELINE_LOG
  exit 1
fi

if [ -f "bbb_to_audio/output/$MEETING_NAME.wav" ]; then
  echo "WARNING: Audio for $MEETING_NAME already exists and will not be regenerated. Run 'rm bbb_to_audio/output/$MEETING_NAME.wav' to delete it." | tee -a $PIPELINE_LOG
fi

if [ -f "audio_to_transcript/output/$MEETING_NAME.txt" ]; then
  echo "WARNING: Transcript for $MEETING_NAME already exists. Run 'rm audio_to_transcript/output/$MEETING_NAME.txt' to delete it." | tee -a $PIPELINE_LOG
fi
echo "*******************************************************************************************************************************"
echo ""




echo "Setting up services ... " | tee -a $PIPELINE_LOG
echo ""
docker compose up -d > $DOCKER_LOG 2>&1 &

sleep 5
nohup docker compose logs -f >> $DOCKER_LOG 2>&1 &

echo "STARTING PIPELINE FOR MEETING '$MEETING_NAME'" | tee -a $PIPELINE_LOG

if [[ "$URL" != "" && ! -f "bbb_to_audio/output/$MEETING_NAME.wav" ]]; then
  echo "- Generating audio from BBB Meeting ... " | tee -a $PIPELINE_LOG
  curl -X POST http://localhost:9000/run   -H "Content-Type: application/json"   -d "{
      \"url\": \"${URL}\",
      \"name\": \"${MEETING_NAME}\"
    }" >> $PIPELINE_LOG 2>&1
fi

# Handle error
if [[ ! -f "bbb_to_audio/output/$MEETING_NAME.wav" ]]; then
  echo "ERROR: Audio generation failed. Shutting down!" | tee -a $PIPELINE_LOG
  docker compose down
  exit 1
fi

if [ ! -f "audio_to_transcript/output/$MEETING_NAME.txt" ]; then
  echo "- Generating transcript from audio ... " | tee -a $PIPELINE_LOG
  curl -X POST http://localhost:9001/run   -H "Content-Type: application/json"   -d "{
      \"model\": \"$WHISPER_MODEL\",
      \"name\": \"${MEETING_NAME}\"
    }" >> $PIPELINE_LOG 2>&1
fi

# Handle error
if [[ ! -f "audio_to_transcript/output/$MEETING_NAME.txt" ]]; then
  echo "ERROR: Transcript generation failed. Shutting down!" | tee -a $PIPELINE_LOG
  docker compose down
  exit 1
fi

if [[ "$PROVIDER" != "ollama" ]]; then
  if [[ "$API_KEY" == "" ]]; then
    echo "ERROR: API key required for provider '$PROVIDER'" | tee -a $PIPELINE_LOG
    docker compose down
    exit 1
  fi

  echo "- Setting model config ..." | tee -a $PIPELINE_LOG
  curl -X POST "http://127.0.0.1:9002/save-model-config" \
    -H "Content-Type: application/json" \
    -d "{
        \"provider\": \"$PROVIDER\",
        \"model\": \"$MODEL\",
        \"whisperModel\": \"$WHISPER_MODEL\",
        \"apiKey\": \"$API_KEY\"
      }" >> $PIPELINE_LOG 2>&1
fi

echo "- Generating summary from transcript ..." | tee -a $PIPELINE_LOG
if [[ "$PROVIDER" == "ollama" ]]; then
  docker exec -it ollama ollama pull $MODEL  >> $PIPELINE_LOG 2>&1
fi

curl -X POST "http://127.0.0.1:9002/process-transcript" \
  -H "Content-Type: application/json" \
  -d "{
      \"model\": \"$PROVIDER\",
      \"model_name\": \"$MODEL\",
      \"meeting_id\": \"$MEETING_NAME\",
      \"chunk_size\": $CHUNK_SIZE,
      \"overlap\": $OVERLAP,
      \"custom_prompt\": \"$CUSTOM_PROMT\"
    }" >> $PIPELINE_LOG 2>&1

while [ ! -f "transcript_to_summary/output/$MEETING_NAME.txt" ]; do
  echo "  - Summary generation in progress ..." | tee -a $PIPELINE_LOG
  sleep 10
  curl -X GET "http://127.0.0.1:9002/get-summary/$MEETING_NAME" >> $PIPELINE_LOG 2>&1
done



echo "Terminating services ... " | tee -a $PIPELINE_LOG
docker compose down