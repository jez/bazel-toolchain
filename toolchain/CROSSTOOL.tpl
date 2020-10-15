# Copyright 2018 The Bazel Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

major_version: "unknown"
minor_version: ""

default_target_cpu: "" # Deprecated, but a required field in bazel 0.18 and less.

# Dummy toolchain to satisfy constraints on cc_toolchain in local_config_cc;
# these constraints are enforced even when nothing depends on local_config_cc.
# The bug was introduced in bazel 0.19, and fixed in
# https://github.com/bazelbuild/bazel/commit/683c302129b66a8999f986be5ae7e642707e978c
toolchain {
  toolchain_identifier: "local"
  abi_version: "local"
  abi_libc_version: "local"
  compiler: "local"
  host_system_name: "local"
  target_system_name: "local"
  target_cpu: "local"
  target_libc: "local"
}

toolchain {
  toolchain_identifier: "clang-linux"
  abi_version: "clang"
  abi_libc_version: "glibc_unknown"
  compiler: "clang"
  host_system_name: "x86_64"
  needsPic: true
  supports_incremental_linker: false
  supports_fission: false
  supports_interface_shared_objects: false
  supports_normalizing_ar: false
  supports_start_end_lib: true
  supports_gold_linker: true
  target_libc: "glibc_unknown"
  target_cpu: "k8"
  target_system_name: "x86_64-unknown-linux-gnu"

  builtin_sysroot: "%{sysroot_path}"

  # Working with symlinks; anticipated to be a future default.
  compiler_flag: "-no-canonical-prefixes"
  linker_flag: "-no-canonical-prefixes"

  # Reproducibility.
  unfiltered_cxx_flag: "-Wno-builtin-macro-redefined"
  unfiltered_cxx_flag: "-D__DATE__=\"redacted\""
  unfiltered_cxx_flag: "-D__TIMESTAMP__=\"redacted\""
  unfiltered_cxx_flag: "-D__TIME__=\"redacted\""
  unfiltered_cxx_flag: "-fdebug-prefix-map=%{toolchain_path_prefix}=%{debug_toolchain_path_prefix}"

  # Security
  compiler_flag: "-U_FORTIFY_SOURCE"
  compiler_flag: "-fstack-protector"
  compiler_flag: "-fcolor-diagnostics"
  compiler_flag: "-fno-omit-frame-pointer"

  # Diagnostics
  compiler_flag: "-Wall"

  # C++
  cxx_flag: "-std=c++17"
  cxx_flag: "-stdlib=libc++"
  # The linker has no way of knowing if there are C++ objects; so we always link C++ libraries.
  linker_flag: "-L%{toolchain_path_prefix}lib"
  linker_flag: "-l:libc++.a"
  linker_flag: "-l:libc++abi.a"
  linker_flag: "-l:libunwind.a"
  cxx_flag: "-DLIBCXX_USE_COMPILER_RT=YES"
  linker_flag: "-rtlib=compiler-rt"
  linker_flag: "-lpthread"  # For libunwind
  linker_flag: "-ldl"  # For libunwind

  # Linker
  linker_flag: "-lm"
  linker_flag: "-fuse-ld=lld"
  linker_flag: "-Wl,--build-id=md5"
  linker_flag: "-Wl,--hash-style=both"
  linker_flag: "-Wl,-z,relro,-z,now"

  # Syntax for include directories is mentioned at:
  # https://github.com/bazelbuild/bazel/blob/d61a185de8582d29dda7525bb04d8ffc5be3bd11/src/main/java/com/google/devtools/build/lib/rules/cpp/CcToolchain.java#L125
  cxx_builtin_include_directory: "%{toolchain_path_prefix}include/c++/v1"
  cxx_builtin_include_directory: "%{toolchain_path_prefix}lib/clang/%{llvm_version}/include"
  cxx_builtin_include_directory: "%{sysroot_prefix}/include"
  cxx_builtin_include_directory: "%{sysroot_prefix}/usr/include"
  cxx_builtin_include_directory: "%{sysroot_prefix}/usr/local/include"

  objcopy_embed_flag: "-I"
  objcopy_embed_flag: "binary"

  tool_path {name: "ld" path: "%{tools_path_prefix}bin/ld.lld" }
  tool_path {name: "cpp" path: "%{tools_path_prefix}bin/clang-cpp" }
  tool_path {name: "dwp" path: "%{tools_path_prefix}bin/llvm-dwp" }
  tool_path {name: "gcov" path: "%{tools_path_prefix}bin/llvm-profdata" }
  tool_path {name: "nm" path: "%{tools_path_prefix}bin/llvm-nm" }
  tool_path {name: "objcopy" path: "%{tools_path_prefix}bin/llvm-objcopy" }
  tool_path {name: "objdump" path: "%{tools_path_prefix}bin/llvm-objdump" }
  tool_path {name: "strip" path: "/usr/bin/strip" }
  tool_path {name: "gcc" path: "%{tools_path_prefix}bin/clang" }
  tool_path {name: "ar" path: "%{tools_path_prefix}bin/llvm-ar" }

  compilation_mode_flags {
    mode: DBG
    compiler_flag: "-g"
    compiler_flag: "-fstandalone-debug"
  }

  compilation_mode_flags {
    mode: OPT
    compiler_flag: "-g0"
    compiler_flag: "-O2"
    compiler_flag: "-D_FORTIFY_SOURCE=1"
    compiler_flag: "-DNDEBUG"
    compiler_flag: "-ffunction-sections"
    compiler_flag: "-fdata-sections"
    linker_flag: "-Wl,--gc-sections"
  }

  linking_mode_flags { mode: DYNAMIC }

  feature {
    name: 'coverage'
    provides: 'profile'
    flag_set {
      action: 'preprocess-assemble'
      action: 'c-compile'
      action: 'c++-compile'
      action: 'c++-header-parsing'
      action: 'c++-module-compile'
      flag_group {
        flag: '-fprofile-instr-generate'
        flag: '-fcoverage-mapping'
      }
    }
    flag_set {
      action: 'c++-link-dynamic-library'
      action: 'c++-link-nodeps-dynamic-library'
      action: 'c++-link-executable'
      flag_group {
        flag: '-fprofile-instr-generate'
      }
    }
  }
}

toolchain {
  toolchain_identifier: "clang-darwin"
  host_system_name: "x86_64-apple-macosx"
  target_system_name: "x86_64-apple-macosx"
  target_cpu: "darwin"
  target_libc: "macosx"
  compiler: "clang"
  abi_version: "darwin_x86_64"
  abi_libc_version: "darwin_x86_64"
  needsPic: false

  builtin_sysroot: "%{sysroot_path}"

  # Working with symlinks
  compiler_flag: "-no-canonical-prefixes"
  linker_flag: "-no-canonical-prefixes"

  # Reproducibility.
  unfiltered_cxx_flag: "-Wno-builtin-macro-redefined"
  unfiltered_cxx_flag: "-D__DATE__=\"redacted\""
  unfiltered_cxx_flag: "-D__TIMESTAMP__=\"redacted\""
  unfiltered_cxx_flag: "-D__TIME__=\"redacted\""
  unfiltered_cxx_flag: "-fdebug-prefix-map=%{toolchain_path_prefix}=%{debug_toolchain_path_prefix}"

  # Security
  compiler_flag: "-D_FORTIFY_SOURCE=1"
  compiler_flag: "-fstack-protector"
  compiler_flag: "-Wthread-safety"
  compiler_flag: "-Wself-assign"
  compiler_flag: "-fno-omit-frame-pointer"

  # Diagnostics
  compiler_flag: "-fcolor-diagnostics"
  compiler_flag: "-Wall"

  # C++
  cxx_flag: "-std=c++17"
  cxx_flag: "-stdlib=libc++"
  # The linker has no way of knowing if there are C++ objects; so we always link C++ libraries.
  linker_flag: "-L%{toolchain_path_prefix}lib"
  linker_flag: "-lc++-static"
  linker_flag: "-lc++abi-static"

  # Linker
  linker_flag: "-lm"
  linker_flag: "-headerpad_max_install_names"

  # Syntax for include directories is mentioned at:
  # https://github.com/bazelbuild/bazel/blob/d61a185de8582d29dda7525bb04d8ffc5be3bd11/src/main/java/com/google/devtools/build/lib/rules/cpp/CcToolchain.java#L125
  cxx_builtin_include_directory: "%{toolchain_path_prefix}include/c++/v1"
  cxx_builtin_include_directory: "%{toolchain_path_prefix}lib/clang/%{llvm_version}/include"
  cxx_builtin_include_directory: "%{sysroot_prefix}/usr/include"
  cxx_builtin_include_directory: "%{sysroot_prefix}/System/Library/Frameworks"
  cxx_builtin_include_directory: "/Library/Frameworks"

  objcopy_embed_flag: "-I"
  objcopy_embed_flag: "binary"

  tool_path {name: "ld" path: "%{tools_path_prefix}bin/ld" }  # lld is not ready for macOS.
  tool_path {name: "cpp" path: "%{tools_path_prefix}bin/clang-cpp" }
  tool_path {name: "dwp" path: "%{tools_path_prefix}bin/llvm-dwp" }
  tool_path {name: "gcov" path: "%{tools_path_prefix}bin/llvm-profdata" }
  tool_path {name: "nm" path: "%{tools_path_prefix}bin/llvm-nm" }
  tool_path {name: "objcopy" path: "%{tools_path_prefix}bin/llvm-objcopy" }
  tool_path {name: "objdump" path: "%{tools_path_prefix}bin/llvm-objdump" }
  tool_path {name: "strip" path: "/usr/bin/strip" }
  tool_path {name: "gcc" path: "%{tools_path_prefix}bin/cc_wrapper.sh" }
  tool_path {name: "ar" path: "/usr/bin/libtool" }  # system provided libtool is preferred.

  compilation_mode_flags {
    mode: FASTBUILD
    compiler_flag: "-O0"
    compiler_flag: "-DDEBUG"
  }

  compilation_mode_flags {
    mode: OPT
    compiler_flag: "-g0"
    compiler_flag: "-O2"
    compiler_flag: "-D_FORTIFY_SOURCE=1"
    compiler_flag: "-DNDEBUG"
    compiler_flag: "-ffunction-sections"
    compiler_flag: "-fdata-sections"
  }

  compilation_mode_flags {
    mode: DBG
    compiler_flag: "-g"
  }

  linking_mode_flags {
    mode: DYNAMIC
    linker_flag: "-undefined"
    linker_flag: "dynamic_lookup"
  }

  make_variable {
    name: "STACK_FRAME_UNLIMITED"
    value: "-Wframe-larger-than=100000000 -Wno-vla"
  }

  linking_mode_flags { mode: DYNAMIC }

  feature {
    name: "framework_paths"
    flag_set {
      action: "objc-compile"
      action: "objc++-compile"
      action: "objc-executable"
      action: "objc++-executable"
      flag_group {
        flag: "-F%{framework_paths}"
        iterate_over: "framework_paths"
      }
    }
  }

  feature {
    name: 'coverage'
    provides: 'profile'
    flag_set {
      action: 'preprocess-assemble'
      action: 'c-compile'
      action: 'c++-compile'
      action: 'c++-header-parsing'
      action: 'c++-module-compile'
      flag_group {
        flag: '-fprofile-instr-generate'
        flag: '-fcoverage-mapping'
      }
    }
    flag_set {
      action: 'c++-link-dynamic-library'
      action: 'c++-link-nodeps-dynamic-library'
      action: 'c++-link-executable'
      flag_group {
        flag: '-fprofile-instr-generate'
      }
    }
  }
}
