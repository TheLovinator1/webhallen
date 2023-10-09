#!/bin/bash

# Exit on error
set -e
set -o pipefail

# Check if curl is installed
if ! command -v curl &>/dev/null; then
    echo "curl is not installed. Please install it before running this script."
    exit 1
fi

# Check if jq is installed
if ! command -v jq &>/dev/null; then
    echo "jq is not installed. Please install it before running this script."
    exit 1
fi

# Check if xq is installed
if ! command -v xq &>/dev/null; then
    echo "xq is not installed. Please install it before running this script. https://github.com/sibprogrammer/xq/blob/master/README.md#installation"
    exit 1
fi

# API endpoints to scrape, feel free to add more if you find any
echo "Scraping API endpoints."
mkdir -p api

# Scrape the endpoints manually
curl "https://cdn.webhallen.com/api/section/tree/sv" | jq --sort-keys >"api/categories.json" &
curl "https://cdn.webhallen.com/api/store/se" | jq --sort-keys >"api/stores.json" &
curl "https://cdn.webhallen.com/api/localization/pack" | jq --sort-keys >"api/localization.json" &
curl "https://www.webhallen.com/api/product/recent" | jq --sort-keys >"api/recent_products.json" &
curl "https://www.webhallen.com/api/me" | jq --sort-keys >"api/me.json" &
curl "https://cdn.webhallen.com/api/webhallen-financing/campaign" | jq --sort-keys >"api/financing.json" &
curl "https://www.webhallen.com/api/cart" | jq --sort-keys >"api/cart.json" &
curl "https://cdn.webhallen.com/api/site-message/se/sv" | jq --sort-keys >"api/site_message_se_sv.json" &
curl "https://cdn.webhallen.com/api/site-message/" | jq --sort-keys >"api/site_message.json" &

# Scrape robots.txt
echo "Scraping robots.txt."
mkdir -p misc
curl 'https://www.webhallen.com/robots.txt' >misc/robots.txt

# Scrape sitemaps
echo "Scraping sitemaps."
mkdir -p sitemap

# Add all sitemaps to the sitemap folder
curl "https://www.webhallen.com/sitemap.xml" | xq >"sitemap/sitemap.xml" &
curl "https://www.webhallen.com/sitemap.section.xml" | xq >"sitemap/sitemap.section.xml" &
curl "https://www.webhallen.com/sitemap.category.xml" | xq >"sitemap/sitemap.category.xml" &
curl "https://www.webhallen.com/sitemap.campaign.xml" | xq >"sitemap/sitemap.campaign.xml" &
curl "https://www.webhallen.com/sitemap.campaignList.xml" | xq >"sitemap/sitemap.campaignList.xml" &
curl "https://www.webhallen.com/sitemap.infoPages.xml" | xq >"sitemap/sitemap.infoPages.xml" &
curl "https://www.webhallen.com/sitemap.product.xml" | xq >"sitemap/sitemap.product.xml" &
curl "https://www.webhallen.com/sitemap.manufacturer.xml" | xq >"sitemap/sitemap.manufacturer.xml" &
curl "https://www.webhallen.com/sitemap.article.xml" | xq >"sitemap/sitemap.article.xml" &

# Wait for all curl processes to finish
wait

# Scrape all URLs from the sitemaps
mkdir -p urls
for file in sitemap/*.xml; do
    output_file="urls/$(basename "$file" .xml).txt"
    cat "$file" | grep -oP '(?<=<loc>)[^<]+' | sort -u > "$output_file"
done

# Add all files to git and commit
git add -A

# Commit with the current timestamp
git commit -m "Latest data: $(date -u)" || exit 0

# Only push if the environment variable is set
# 'PUSH_ENABLED=true ./scrape.sh' to enable
# Or 'export PUSH_ENABLED=true' to enable for the current session
if [ "$PUSH_ENABLED" = "true" ]; then
    git push
else
    echo "Environment variable not set. Skipping git push."
fi
