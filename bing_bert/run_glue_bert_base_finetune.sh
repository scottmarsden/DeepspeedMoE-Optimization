LOG_DIR="log"
if [ ! -d "$LOG_DIR" ]; then
  mkdir $LOG_DIR
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

NGPU=1

echo "Started scripts"

MASTER_PORT=$1

config=$2
echo $config
EFFECTIVE_BATCH_SIZE=$(echo $config | cut -f1 -d' ')
LR=$(echo $config | cut -f2 -d' ')
NUM_EPOCH=$(echo $config | cut -f3 -d' ')

model_name="bert_base"
JOBNAME=$3
CHECKPOINT_PATH=$4
OUTPUT_DIR="${SCRIPT_DIR}/outputs/${model_name}/${JOBNAME}_bsz${EFFECTIVE_BATCH_SIZE}_lr${LR}_epoch${NUM_EPOCH}"

GLUE_DIR="/data/GlueData"

MAX_GPU_BATCH_SIZE=32
PER_GPU_BATCH_SIZE=$((EFFECTIVE_BATCH_SIZE/NGPU))
if [[ $PER_GPU_BATCH_SIZE -lt $MAX_GPU_BATCH_SIZE ]]; then
       GRAD_ACCUM_STEPS=1
else
       GRAD_ACCUM_STEPS=$((PER_GPU_BATCH_SIZE/MAX_GPU_BATCH_SIZE))
fi

for TASK in SST-2 MNLI CoLA STS-B QQP MNLI-MM QNLI RTE WNLI MRPC
    do
       echo "Fine Tuning $CHECKPOINT_PATH"
       run_cmd="python3.6 -m torch.distributed.launch \
              --nproc_per_node=${NGPU} \
              --master_port=${MASTER_PORT} \
              run_glue_classifier_bert_base.py \
              --task_name $TASK \
              --do_train \
              --do_eval \
              --do_lower_case \
              --data_dir $GLUE_DIR/$TASK/ \
              --bert_model bert-large-uncased \
              --max_seq_length 128 \
              --train_batch_size ${PER_GPU_BATCH_SIZE} \
              --gradient_accumulation_steps ${GRAD_ACCUM_STEPS} \
              --learning_rate ${LR} \
              --num_train_epochs ${NUM_EPOCH} \
              --output_dir ${OUTPUT_DIR}_${TASK} \
              --progressive_layer_drop \
              --model_file $CHECKPOINT_PATH &> $LOG_DIR/${model_name}/${JOBNAME}_${TASK}_bzs${EFFECTIVE_BATCH_SIZE}_lr${LR}_epoch${NUM_EPOCH}.txt
              "
       echo ${run_cmd}
       eval ${run_cmd} 
    done   
