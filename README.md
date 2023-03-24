**IMPORTANT:** This repo is depreceted. For up to date information on verifying Transormation Advisor signatures, please see the documentation: https://www.ibm.com/docs/en/cta?topic=planning-security-considerations

================

## Verify Transformation Advisor Images

### Pre-req

Install `Skopeo` tool. Please use version 0.1.40+ and non-dev version.

See here for more details: https://github.com/containers/skopeo/blob/main/install.md

### Steps to verify

1. Pull docker images from docker hub, e.g.

        # pull down the test image
        docker pull icr.io/appcafe/transformation-advisor-ui:sample-image-signing-eabde5e

2. Copy from local docker repo to a location:

        # the location where you want to copy the image to
        mkdir -p /Users/ibm/Downloads/transformation-advisor/docker

        skopeo copy --dest-tls-verify=false \
        docker-daemon:icr.io/appcafe/icp-transformation-advisor-ui:sample-image-signing-eabde5e \
        dir:/Users/ibm/Downloads/transformation-advisor/docker

3. Download the signature, keys and certs from this repo. If you plan to verify Transformation Advisor 3.0 or older, 
the signature, keys and certs are in the folder `TA_3.0_and_older`

        # signature of the image icr.io/appcafe/icp-transformation-advisor-ui:sample-image-signing-eabde5e is located below:
        https://github.com/TransformationAdvisor/public/tree/master/sample/signature-sample-eabde5e

        The signature is used to verify the image

        # keys and certs
        tasigningcert-public.gpg: public key is used to to verify signature
        tasigningcert.pem: certificate is used to to verify public key
        tasigningcert-chain0.pem: certificate chain 0 is used to verify certificate validity, hosted on www.digicert.com

4. Import public key

        # import
        gpg2 --import tasigningcert-public.gpg

        # verify
        gpg2 -k --fingerprint

        -----------------------------
        pub   rsa4096 2022-03-14 [SCEA]
              A3F3 5961 C24A 1028 D13E  6EF8 E65C C90E B50C F6E5
        uid           [ unknown] tasigningcert

5. Verify the cert

        openssl x509 -text -in tasigningcert.pem

        Signature Algorithm: sha256WithRSAEncryption
            Issuer: C=US, O=DigiCert Inc, OU=www.digicert.com, CN=DigiCert SHA2 Assured ID Code Signing CA
            Validity
                Not Before: Apr 22 00:00:00 2020 GMT
                Not After : Apr 27 12:00:00 2022 GMT
            Subject: C=US, ST=New York, L=Armonk, O=International Business Machines Corporation, OU=IBM CCSS, CN=International Business Machines Corporation

6. Verify the image with signature

        # location of the manifest.json: /Users/ibm/Downloads/transformation-advisor/docker/manifest.json
        # docker reference: transformation-advisor 
        # The same docker reference is used for all the images
        # the imported public key fingerprint: A3F35961C24A1028D13E6EF8E65CC90EB50CF6E5
        # the downloaded singature: /Users/ibm/Downloads/signature-sample-eabde5e
      
        skopeo standalone-verify \
        /Users/ibm/Downloads/transformation-advisor/docker/manifest.json \
        transformation-advisor \
        A3F35961C24A1028D13E6EF8E65CC90EB50CF6E5 \
        /Users/ibm/Downloads/signature-sample-eabde5e

        Signature verified, digest sha256:c84367ae8593c428d8174ed33097e31518169ac94e5cc03742ef1ff78d94bd5f

7. Verify the signature with keys and certs

        openssl ocsp -no_nonce \
        -issuer /Users/ibm/Downloads/tasigningcert-chain0.pem \
        -cert /Users/ibm/Downloads/tasigningcert.pem \
        -VAfile /Users/ibm/Downloads/tasigningcert-chain0.pem \
        -text -url http://ocsp.digicert.com \
        -respout ocsptest
        
        ...
        Response verify OK
        /Users/ibm/Downloads/tasigningcert.pem: good
            This Update: Jun 16 07:57:34 2020 GMT
            Next Update: Jun 23 07:12:34 2020 GMT
