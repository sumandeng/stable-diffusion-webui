FROM alpine/git:latest as download

SHELL ["/bin/sh", "-ceuxo", "pipefail"]

RUN apk add parallel aria2

RUN mkdir -p /data/StableDiffusion \
    && aria2c "https://drive.yerf.org/wl/?id=EBfTrmcCCUAGaQBXVIj5lJmEhjoP1tgl&mode=grid&download=1" \
      --continue --dir /data/StableDiffusion --out model.ckpt

RUN echo 'git clone --depth=1 "$2" repositories/"$1" && rm -rf .git' > /clone.sh

RUN . /clone.sh taming-transformers https://github.com/CompVis/taming-transformers.git 24268930bf1dce879235a7fddd0b2355b84d7ea6 \
  && rm -rf data assets **/*.ipynb

RUN . /clone.sh stable-diffusion https://github.com/CompVis/stable-diffusion.git 69ae4b35e0a0f6ee1af8bb9a5d0016ccb27e36dc \
  && rm -rf assets data/**/*.png data/**/*.jpg data/**/*.gif

RUN . /clone.sh CodeFormer https://github.com/sczhou/CodeFormer.git c5b4593074ba6214284d6acd5f1719b6c5d739af \
  && rm -rf assets inputs

RUN . /clone.sh BLIP https://github.com/salesforce/BLIP.git 48211a1594f1321b00f14c9f7a5b4813144b2fb9
RUN . /clone.sh k-diffusion https://github.com/crowsonkb/k-diffusion.git 60e5042ca0da89c14d1dd59d73883280f8fce991
RUN . /clone.sh clip-interrogator https://github.com/pharmapsychotic/clip-interrogator 2486589f24165c8e3b303f84e9dbbea318df83e8


#FROM pytorch/pytorch:1.12.1-cuda11.3-cudnn8-runtime
FROM pytorch/pytorch:1.11.0-cuda11.3-cudnn8-runtime
#FROM ccr.ccs.tencentyun.com/tione-public-images/ti-infer-gpu-base:1.0.0

SHELL ["/bin/bash", "-ceuxo", "pipefail"]
ENV DEBIAN_FRONTEND=noninteractive PIP_PREFER_BINARY=1 PIP_NO_CACHE_DIR=1

ENV PROJECT_NAME=stable-diffusion
ENV APP_DIR=/${PROJECT_NAME}
WORKDIR ${APP_DIR}
COPY . ${APP_DIR}

# copy dependency files
COPY --from=download /git/ ${APP_DIR}
COPY --from=download /data/StableDiffusion/model.ckpt ${APP_DIR}

RUN apt update && apt install git -y
RUN pip install torch --extra-index-url https://download.pytorch.org/whl/cu113 \
    && pip install transformers==4.19.2 diffusers invisible-watermark --prefer-binary \
    && pip install git+https://github.com/crowsonkb/k-diffusion.git --prefer-binary \
    && pip install git+https://github.com/TencentARC/GFPGAN.git --prefer-binary \
    && pip install -r repositories/CodeFormer/requirements.txt --prefer-binary \
    && pip install -r requirements.txt  --prefer-binary \
    && pip install -U numpy  --prefer-binary

EXPOSE 8501
CMD python3 webui.py --listen --port 8501

