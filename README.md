以下のコマンドでBoostをBuildしてoutに出力することができる.

```
docker build \
     --output out \
     -f boost.Dockerfile \
     --build-arg BOOST_VERSION=1.80.0 \
     --build-arg GCC_VERSION=13 \

```

# lint

```
docker run --rm -i docker.io/hadolint/hadolint < boost.Dockerfile
```
