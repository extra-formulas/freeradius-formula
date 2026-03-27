# Instructions for developers

## Testing

Using Docker, on the root of the repo

```
docker build -f tests/CentOS-9.dockerfile -t saltstack-freeradius-formula:CentOS-9 .
docker run --rm -it saltstack-freeradius-formula:CentOS-9
```