# Rails Docker Sandbox

Practice of Dockerize Ruby on Rails application.

## Build

```
$ docker build -t rails .
```

## Run

Show routes:

```
$ docker run rails routes
```

Boot rails server (with port binding):

```
$ docker run -p 3000:3000 rails server
```

and you can execute any rails commands.
