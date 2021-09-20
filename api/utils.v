// Copyright (c) 2020 vpkg developers
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

module api

import os

fn delete_package_contents(path string) ? {
	os.walk(path, os.rm)

	new_folder_contents := os.ls(path) ?
	if new_folder_contents.len == 0 {
		os.rmdir(path) ?
	}

	return 
}

const illegal_chars = [byte(`-`)]

fn sanitize_package_name(name string) string {
	mut name_array := name.bytes()
	for i, chr in name_array {
		if chr in illegal_chars {
			name_array[i] = `_`
		}
	}
	return name_array.bytestr()
}

pub fn (vpkg &Vpkg) create_modules_dir() ?string {
	if !os.exists(vpkg.dir) {
		os.mkdir(vpkg.dir) ?
	}

	return vpkg.dir
}

fn to_fs_path(name string) string {
	return name.replace('.', os.path_separator)
}