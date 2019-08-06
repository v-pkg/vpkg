module main

import os
import json
import term

fn load_package_file() PkgInfo {
    vpkg_file := os.read_file('${os.getwd()}/.vpkg.json') or {
        eprintln(term.red('No .vpkg.json found.'))
        return PkgInfo{'', []string, '', '', []string}
    }

    pkg_info := json.decode(PkgInfo, vpkg_file) or {
        eprintln(term.red('Error decoding .vpkg.json'))
        return PkgInfo{'', []string, '', '', []string}
    }

    return pkg_info
}

fn check_git_version(dir string) string {
    version := os.exec('git --git-dir ${dir}/.git log --pretty=format:%H -n 1')

    return version
}

fn read_lockfile() ?Lockfile {
    contents := os.read_file(LockfilePath) or {
        return error('Project lockfile not found.')
    }

    decoded := json.decode(Lockfile, contents) or {
        return error('Unable to decode lockfile.')
    }

    return decoded
}

fn (lock mut Lockfile) find_package(name string) int {
    for idx, package in lock.packages {
        if package.name == name {
            return idx
        }
    }

    return -1
}

fn (lock mut Lockfile) regenerate(packages []InstalledPackage, remove bool) {    
    if lock.version != Version {
        lock.version = Version
    }
 
    if remove {
        for package in packages {
            package_idx := lock.find_package(package.name)

            if package_idx != -1 {
                lock.packages.delete(package_idx)
            }
        }
    } else {
        for package in packages {
            package_idx := lock.find_package(package.name)

            if package_idx != -1 {
                lock.packages[package_idx] = InstalledPackage{
                    name: package.name,
                    path: package.path
                    version: package.version
                }
            } else {
                lock.packages << InstalledPackage{
                    name: package.name,
                    path: package.path
                    version: package.version
                }
            }
        }
    }

    // stringify contents
    mut contents := ['{', '\n', '   "version": "${lock.version}",\n', '   "packages": [\n']

    for i := 0; i < lock.packages.len; i++ {
        pkg := lock.packages[i]

        contents << '       {\n'
        contents << '           "name": "${pkg.name}",\n'
        contents << '           "version": "${pkg.version}"\n'
        contents << '       }'

        if i != lock.packages.len-1 {
            contents << ',\n'
        } else {
            contents << '\n'
        }
    }

    contents << '   ]\n'
    contents << '}'

    os.write_file(LockfilePath, contents.join(''))
    contents.free()
}

fn create_lockfile() Lockfile {
    lockfile_json_arr := ['{', '\n', '   "version": "${Version}",\n', '   "packages": []\n', '}']

    lockfile := os.create(LockfilePath) or {
        return Lockfile{Version, []InstalledPackage}
    }

    lockfile_json := lockfile_json_arr.join('')

    lockfile.write(lockfile_json)
    defer { lockfile.close() }

    contents := read_lockfile() or {
        return Lockfile{Version, []InstalledPackage}
    }

    return contents
}


fn delete_package_contents(path string) bool {
    mut folder_contents := os.ls(path)

    for i := 0; i < folder_contents.len; i++ {
        filename := folder_contents[i]
        filepath := '${path}/${filename}'

        if os.dir_exists(filepath) {
            delete_package_contents(filepath)
        } else {
            os.rm(filepath)
        }
    }

    folder_contents = os.ls(path)

    if folder_contents.len == 0 {
        os.rmdir(path)

        return true
    } else {
        return false
    }
}

fn package_name(name string) string {
    is_git := is_git_url(name)
    mut pkg_name := name

    if is_git {
        pkg_name = os.filename(name)
    }

    if is_git && name.contains('.git') {
        pkg_name = pkg_name.replace('.git', '')
    }

    if name.starts_with('v-') {
        pkg_name = pkg_name.all_after('v-')
    }

    return pkg_name
}

fn create_modules_dir() string {
    if os.dir_exists(ModulesDir) {
        os.mkdir(ModulesDir)
    }

    return ModulesDir
}

fn is_git_url(a string) bool {
    protocols := ['https://', 'git://']

    for i := 0; i < protocols.len; i++ {
        if a.starts_with(protocols[i]) {
            return true
        }
    }

    return false
}