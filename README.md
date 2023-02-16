
# Certificate Generator
This script will generate a Self-Signed certificate for you - It supports multidomain (wildcards).

## Description
Sometimes having you Apps running with SSH protocols is mandatory and generating certificates becomes into a frequent/eventual task and it is not always easy to remember all those commands. Nothing better than a script that does all the dirty work for you :smirk:.

# Prerequisites

The only thing you need besides PowerShell is a .cnf fiel with all the domains you want to be covered (wildcards).
```
    [ req ]    
    default_bits = 4096    
    distinguished_name = req_distinguished_name    
    req_extensions = SAN    
    extensions = SAN    
    [ req_distinguished_name ]    
    countryName = myCountry    
    stateOrProvinceName = myProvince    
    localityName = myCity    
    organizationName = myOrgan    
    [SAN]    
    subjectAltName = DNS:my.domaine.any,IP:999.999.999    
    extendedKeyUsage = serverAuth    
    basicConstraints = CA:TRUE,pathlen:0    
    default_bits = 4096    
    distinguished_name = req_distinguished_name    
    req_extensions = SAN    
    extensions = SAN    
    [ req_distinguished_name ]    
    countryName = myCountry    
    stateOrProvinceName = myProvince    
    localityName = myCity    
    organizationName = myOrgan    
    [SAN]    
    subjectAltName = DNS:my.domaine.any,IP:999.999.999    
    extendedKeyUsage = serverAuth    
    basicConstraints = CA:TRUE,pathlen:0
```