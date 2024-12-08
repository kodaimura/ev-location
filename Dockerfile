FROM julia:1.11

WORKDIR /app

COPY . /app

RUN julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()'