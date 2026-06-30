{ pkgs, ... }:

{
  # Некоторые программы (например JetBrains IDEA) скачивают предсобранные нативные
  # бинарники в ~/.cache и запускают их напрямую — в частности embeddings-server
  # для semantic-search/AI. Это обычные ELF, слинкованные на стандартный загрузчик
  # /lib64/ld-linux-x86-64.so.2, которого в NixOS нет, поэтому они падают с
  # "Could not start dynamically linked executable".
  #
  # nix-ld ставит загрузчик-шим по стандартному пути и подсовывает нужные
  # библиотеки через NIX_LD_LIBRARY_PATH. Менять файлы в ~/.cache бесполезно —
  # IDEA перекачивает их при обновлении.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib # libstdc++ / libgcc_s
      zlib
      openssl
    ];
  };
}
