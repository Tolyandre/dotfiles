#! /usr/bin/env nix-shell
#! nix-shell -i bash -p bash

dir1="$1"
dir2="$2"

if [[ -z "$dir1" || -z "$dir2" ]]; then
  echo "Usage: $0 <directory1> <directory2>"
  exit 1
fi

if [[ ! -d "$dir1" || ! -d "$dir2" ]]; then
  echo "Одна из директорий не существует."
  exit 2
fi

tmp1=$(mktemp)
tmp2=$(mktemp)

find "$dir1" -path "$dir2" -prune -o -type f -printf "%f\n" | sort > "$tmp1"
find "$dir2" -path "$dir1" -prune -o -type f -printf "%f\n" | sort > "$tmp2"

echo "Файлы, присутствующие в обеих директориях:"
comm -12 "$tmp1" "$tmp2"

rm "$tmp1" "$tmp2"
