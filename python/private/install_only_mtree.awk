# Normalize install_only archive entries after tar.bzl's default mutation.

{
    sub(/^/, "python/")
}

/ type=dir/ {
    next
}

{
    mode = "0644"
    if ($1 ~ /^python\/bin\// || $1 ~ /\.(dll|dylib|exe|pyd|so)$/) {
        mode = "0755"
    }
    sub(/mode=[0-9]+/, "mode=" mode)

    if ($0 !~ / uname=/) {
        $0 = $0 " uname=root"
    }
    if ($0 !~ / gname=/) {
        $0 = $0 " gname=root"
    }

    if (add_python_symlinks == "1" && $1 == "python/bin/python" python_version) {
        link_metadata = " uid=0 gid=0 uname=root gname=root time=1704067200 mode=0777 type=link link=python" python_version
        print "python/bin/python" link_metadata
        print "python/bin/python3" link_metadata
    }
}
