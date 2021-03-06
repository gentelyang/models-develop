
#!/bin/bash

export PADDLE_PSERVER_ENDPOINTS="127.0.0.1:7160,127.0.0.1:7161"
export PADDLE_TRAINERS_NUM="2"

mkdir -p logs
train(){
    python  train.py \
      --src_vocab_fpath data/vocab.bpe.32000 \
      --trg_vocab_fpath data/vocab.bpe.32000 \
      --special_token '<s>' '<e>' '<unk>' \
      --train_file_pattern data/train.tok.clean.bpe.32000.en-de \
      --token_delimiter ' ' \
      --use_token_batch True \
      --batch_size 4096 \
      --sort_type pool \
      --pool_size 200000 \
      --shuffle False \
      --enable_ce True \
      --shuffle_batch False \
      --use_py_reader True \
      --use_mem_opt True \
      --use_default_pe False \
      --fetch_steps 100  $@ \
      dropout_seed 10 \
      learning_rate 2.0 \
      warmup_steps 8000 \
      beta2 0.997 \
      d_model 512 \
      d_inner_hid 2048 \
      n_head 8 \
      prepostprocess_dropout 0.1 \
      attention_dropout 0.1 \
      relu_dropout 0.1 \
      weight_sharing True \
      pass_num 1 \
      model_dir 'tmp_models' \
      ckpt_dir 'tmp_ckpts'
}


PADDLE_TRAINING_ROLE="PSERVER" \
PADDLE_CURRENT_ENDPOINT="127.0.0.1:7160" \
train |python _ce.py


PADDLE_TRAINING_ROLE="PSERVER" \
PADDLE_CURRENT_ENDPOINT="127.0.0.1:7161" \
train |python _ce.py

PADDLE_TRAINING_ROLE="TRAINER" \
PADDLE_CURRENT_ENDPOINT="127.0.0.1:7160" \
PADDLE_TRAINER_ID="0" \
CUDA_VISIBLE_DEVICES="0" \
train |python _ce.py

PADDLE_TRAINING_ROLE="TRAINER" \
PADDLE_CURRENT_ENDPOINT="127.0.0.1:7161" \
PADDLE_TRAINER_ID="1" \
CUDA_VISIBLE_DEVICES="1" \
train |python _ce.py