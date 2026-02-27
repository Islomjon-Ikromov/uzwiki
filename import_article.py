#!/usr/bin/env python3
"""
Import a Wikipedia article with ALL dependencies (templates, modules, recursively).
"""

import urllib.request
import urllib.parse
import json
import sys
import time

API_URL = 'https://uz.wikipedia.org/w/api.php'
EXPORT_URL = 'https://uz.wikipedia.org/wiki/Special:Export'
UA = 'UzWikiImport/1.0 (local dev)'
OUTPUT_FILE = '/tmp/uzwiki_export.xml'


def api_query(params):
    params['format'] = 'json'
    url = API_URL + '?' + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={'User-Agent': UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())


def get_templates_for_pages(titles):
    """Get all templates/modules transcluded by the given pages."""
    results = set()
    # API allows max 50 titles per query
    title_list = list(titles)
    for i in range(0, len(title_list), 50):
        batch = title_list[i:i+50]
        cont = {}
        while True:
            params = {
                'action': 'query',
                'titles': '|'.join(batch),
                'prop': 'templates',
                'tllimit': '500',
            }
            params.update(cont)
            try:
                data = api_query(params)
            except Exception as e:
                print(f"  Warning: API error for batch, retrying... {e}")
                time.sleep(2)
                try:
                    data = api_query(params)
                except:
                    break

            for page in data.get('query', {}).get('pages', {}).values():
                for t in page.get('templates', []):
                    results.add(t['title'])

            if 'continue' in data:
                cont = data['continue']
            else:
                break
        time.sleep(0.5)  # be nice to Wikipedia
    return results


def collect_all_dependencies(root_title):
    """Recursively collect all template/module dependencies."""
    all_pages = {root_title}
    to_process = {root_title}
    processed = set()
    depth = 0

    while to_process:
        depth += 1
        print(f"Depth {depth}: processing {len(to_process)} pages...")
        new_deps = get_templates_for_pages(to_process)
        processed.update(to_process)

        newly_found = new_deps - all_pages
        if not newly_found:
            break

        print(f"  Found {len(newly_found)} new dependencies")
        all_pages.update(newly_found)
        to_process = newly_found - processed

    return all_pages


def export_pages(pages, output_file):
    """Export pages via Special:Export."""
    pages_text = '\n'.join(sorted(pages))
    print(f"\nExporting {len(pages)} pages...")

    data = urllib.parse.urlencode({
        'catname': '',
        'pages': pages_text,
        'curonly': '1',
        'wpDownload': '1',
        'templates': '',  # we already resolved deps
    }).encode('utf-8')

    req = urllib.request.Request(
        EXPORT_URL,
        data=data,
        headers={
            'User-Agent': UA,
            'Content-Type': 'application/x-www-form-urlencoded',
        }
    )

    with urllib.request.urlopen(req, timeout=120) as r:
        content = r.read()

    with open(output_file, 'wb') as f:
        f.write(content)

    size_mb = len(content) / (1024 * 1024)
    print(f"Exported {size_mb:.2f} MB to {output_file}")
    return len(content)


def main():
    title = sys.argv[1] if len(sys.argv) > 1 else 'Oʻzbekiston'
    print(f"=== Importing '{title}' with all dependencies ===\n")

    # Step 1: Collect all dependencies recursively
    all_pages = collect_all_dependencies(title)

    templates = sorted(p for p in all_pages if p.startswith('Andoza:'))
    modules = sorted(p for p in all_pages if p.startswith('Modul:'))
    articles = sorted(p for p in all_pages if not p.startswith('Andoza:') and not p.startswith('Modul:'))

    print(f"\nTotal pages to import: {len(all_pages)}")
    print(f"  Articles: {len(articles)}")
    print(f"  Templates (Andoza): {len(templates)}")
    print(f"  Modules (Modul): {len(modules)}")

    # Step 2: Export all pages
    export_pages(all_pages, OUTPUT_FILE)

    print(f"\n=== Export complete: {OUTPUT_FILE} ===")
    print("Ready for import into local MediaWiki.")


if __name__ == '__main__':
    main()
