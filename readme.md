
# cloak

This is a quick readme. This is a fork of onetimesecret. The style reflects what you would find at cloak.sh.

## Build Your Image

```
docker build -t openbridge/cloak .
```

## Run Your Image
```
docker run -it -p 80:80 -v /usr/local/redis:/usr/local/redis --env-file ./env/yourfile.env openbridge/cloak:latest
```
Make sure you check out `sample.env` as it contains the expected variables to make sure everything runs well. The `docker-entrypoint.sh` provides context on the configuration and runtime aspects of the container.
