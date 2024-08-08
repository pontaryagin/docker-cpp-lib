以下のコマンドでBoostをBuildしてoutに出力することができる.

```
docker build \
     --output out \
     --build-arg BOOST_VERSION=1.80.0 \
     --build-arg GCC_VERSION=13 \
     --layers=false
```

# debug on erros
- If you build without `--layers=false`, podman will create hash for each layer.
- It is much better to specifying the target that failed for example by `--target boost`
- You can go to the layer just before it fails by `docker run -it --rm <HASH>`, where `<HASH>` refers to the hash of the last layer created.
- Building with layers produce many cache data. You can try `docker builder prune` to remove them.

# clean up
- docker builder prune
- docker image prune --all
- buildah rm --all

# use overlay for podman
- `podman system reset`
- `sudo apt install containers-storage`
- `podman info | grep graphDriverName`  
  the value should change `vfs` to `overlay`

# lint

```
docker run --rm -i docker.io/hadolint/hadolint < boost.Dockerfile
```
