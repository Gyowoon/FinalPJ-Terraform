# 1.USE <grep '\$' ./*> to search what file has env variable($<...>)
# 2.OR USE <grep '[$]' any-file.yaml>
# 3.Substitute Matching line with Real-Value like below:
## sed -i "s/\\\$ACCOUNT_ID/${ACCOUNT_ID}/g" test-file.yaml

# E.g. grep '[$]' ./*.yaml
# Use namespace.yaml ONLY IF NEEDED, since "shop" is pre-installed 

