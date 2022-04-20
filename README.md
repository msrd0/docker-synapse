# docker-synapse [![Build Status](https://drone.msrd0.eu/api/badges/msrd0/docker-synapse/status.svg?ref=refs/heads/main)](https://drone.msrd0.eu/msrd0/docker-synapse)

Docker Image: [`ghcr.io/msrd0/synapse`](https://github.com/users/msrd0/packages/container/package/synapse)

This docker image contains [Synapse](https://github.com/matrix-org/synapse), a matrix
server, with a custom start script that writes environment variables into a config file.
It is based on the latest debian slim docker image.

## Safety Warning

The startup script automatically tells synapse to keep its nose out of your database
setup. That means it no longer refuses to start because it believes you are an idiot.
So please ensure that you are indeed capable of setting up your database in a
future-proof way - if you absolutely have to use a GNU libc based system, **use the
`C` locale and only the `C` locale for your database**. Or just use the Alpine
Linux container - they don't have a record of breaking locale's so far.

If the synapse maintainers decide to break stuff over night again because they think
it's their job to administrate your server, I might have to expand this list in the
future.

## Environment Variables

**tbd**
