Simple Amazon Route 53 Updater
==========================

By Gerard Matthew http://www.gerard.co

## About
This is a simple tool for updating Amazon Route53 for Dynamic DNS 

## Get Started
```bash
  git clone https://github.com/gmatthew/simple-aws-route53-updater.git
  cd simple-aws-route53-updater
  chmod 600 .aws-secrets
```

## AWS Credentials

  * Obtain your zone id, access key and secret from AWS
  * Configure .aws-secrets
```bash
$ cat .aws-secrets
%awsSecretAccessKeys = (
    'webserver' => {
        id => 'aws-access-key-id',
        key => 'change',
    },
);
```
## Install Perl Libraries
```
  cpan -i Digest::MD5
  cpan -i Digest::HMAC_SHA
```

## Run Script 

```
  perl updater.pl -domain DOMAIN_NAME -zoneid ZONE_ID -account ACCOUNT
  perl updater.pl -domain DOMAIN_NAME_1 -domain DOMAIN_NAME_2 -zoneid ZONE_ID -account ACCOUNT
```
* Options
  - ```-domain``` : domain to be updated
  - ```-ttl``` : ttl for record set
  - ```-type``` : type of record (e.g CNAME, A, etc)
  - ```-zoneid``` : zone id
  - ```-comment``` : any notes
  - ```-account``` : account listed within the .aws-secert file (e.g webserver)
  
## Install Cron Job
```
* * * * * cd /path/to/simple-aws-route53-updater/; perl updater.pl -domain DOMAIN_NAME -zoneid ZONE_ID -account ACCOUNT > /tmp/simple-updater.log
```

## Credit
* dnscurl.pl: http://aws.amazon.com/developertools/9706686376855511
