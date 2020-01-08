load("@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "action_config",
    "artifact_name_pattern",
    "env_entry",
    "env_set",
    "feature",
    "feature_set",
    "flag_group",
    "flag_set",
    "make_variable",
    "tool",
    "tool_path",
    "variable_with_value",
    "with_feature_set",
)
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")

def _impl(ctx):
    if (ctx.attr.cpu == "darwin"):
        toolchain_identifier = "clang-darwin"
    elif (ctx.attr.cpu == "k8"):
        toolchain_identifier = "clang-linux"
    else:
        fail("Unreachable")

    if (ctx.attr.cpu == "k8"):
        host_system_name = "x86_64"
    elif (ctx.attr.cpu == "darwin"):
        host_system_name = "x86_64-apple-macosx"
    else:
        fail("Unreachable")

    if (ctx.attr.cpu == "darwin"):
        target_system_name = "x86_64-apple-macosx"
    elif (ctx.attr.cpu == "k8"):
        target_system_name = "x86_64-unknown-linux-gnu"
    else:
        fail("Unreachable")

    if (ctx.attr.cpu == "darwin"):
        target_cpu = "darwin"
    elif (ctx.attr.cpu == "k8"):
        target_cpu = "k8"
    else:
        fail("Unreachable")

    if (ctx.attr.cpu == "k8"):
        target_libc = "glibc_unknown"
    elif (ctx.attr.cpu == "darwin"):
        target_libc = "macosx"
    else:
        fail("Unreachable")

    if (ctx.attr.cpu == "darwin" or
        ctx.attr.cpu == "k8"):
        compiler = "clang"
    else:
        fail("Unreachable")

    if (ctx.attr.cpu == "k8"):
        abi_version = "clang"
    elif (ctx.attr.cpu == "darwin"):
        abi_version = "darwin_x86_64"
    else:
        fail("Unreachable")

    if (ctx.attr.cpu == "darwin"):
        abi_libc_version = "darwin_x86_64"
    elif (ctx.attr.cpu == "k8"):
        abi_libc_version = "glibc_unknown"
    else:
        fail("Unreachable")

    cc_target_os = None

    if (ctx.attr.cpu == "darwin" or
        ctx.attr.cpu == "k8"):
        builtin_sysroot = "%{sysroot_path}"
    else:
        fail("Unreachable")

    all_compile_actions = [
        ACTION_NAMES.c_compile,
        ACTION_NAMES.cpp_compile,
        ACTION_NAMES.linkstamp_compile,
        ACTION_NAMES.assemble,
        ACTION_NAMES.preprocess_assemble,
        ACTION_NAMES.cpp_header_parsing,
        ACTION_NAMES.cpp_module_compile,
        ACTION_NAMES.cpp_module_codegen,
        ACTION_NAMES.clif_match,
        ACTION_NAMES.lto_backend,
    ]

    all_cpp_compile_actions = [
        ACTION_NAMES.cpp_compile,
        ACTION_NAMES.linkstamp_compile,
        ACTION_NAMES.cpp_header_parsing,
        ACTION_NAMES.cpp_module_compile,
        ACTION_NAMES.cpp_module_codegen,
        ACTION_NAMES.clif_match,
    ]

    preprocessor_compile_actions = [
        ACTION_NAMES.c_compile,
        ACTION_NAMES.cpp_compile,
        ACTION_NAMES.linkstamp_compile,
        ACTION_NAMES.preprocess_assemble,
        ACTION_NAMES.cpp_header_parsing,
        ACTION_NAMES.cpp_module_compile,
        ACTION_NAMES.clif_match,
    ]

    codegen_compile_actions = [
        ACTION_NAMES.c_compile,
        ACTION_NAMES.cpp_compile,
        ACTION_NAMES.linkstamp_compile,
        ACTION_NAMES.assemble,
        ACTION_NAMES.preprocess_assemble,
        ACTION_NAMES.cpp_module_codegen,
        ACTION_NAMES.lto_backend,
    ]

    all_link_actions = [
        ACTION_NAMES.cpp_link_executable,
        ACTION_NAMES.cpp_link_dynamic_library,
        ACTION_NAMES.cpp_link_nodeps_dynamic_library,
    ]

    objcopy_embed_data_action = action_config(
        action_name = "objcopy_embed_data",
        enabled = True,
        tools = [tool(path = "%{tools_path_prefix}bin/llvm-objcopy")],
    )

    if (ctx.attr.cpu == "darwin"
        or ctx.attr.cpu == "k8"):
        action_configs = [objcopy_embed_data_action]
    else:
        fail("Unreachable")

    dbg_feature = feature(name = "dbg")

    framework_paths_feature = feature(
        name = "framework_paths",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.objc_compile,
                    ACTION_NAMES.objcpp_compile,
                    "objc-executable",
                    "objc++-executable",
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-F%{framework_paths}"],
                        iterate_over = "framework_paths",
                    ),
                ],
            ),
        ],
    )

    fastbuild_feature = feature(name = "fastbuild")

    coverage_feature = feature(
        name = "coverage",
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["-fprofile-instr-generate", "-fcoverage-mapping"],
                    ),
                ],
            ),
            flag_set(
                actions = [
                    ACTION_NAMES.cpp_link_dynamic_library,
                    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                    ACTION_NAMES.cpp_link_executable,
                ],
                flag_groups = [flag_group(flags = ["-fprofile-instr-generate"])],
            ),
        ],
        provides = ["profile"],
    )

    objcopy_embed_flags_feature = feature(
        name = "objcopy_embed_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = ["objcopy_embed_data"],
                flag_groups = [flag_group(flags = ["-I", "binary"])],
            ),
        ],
    )

    opt_feature = feature(name = "opt")

    supports_dynamic_linker_feature = feature(name = "supports_dynamic_linker", enabled = True)

    dynamic_linking_mode_feature = feature(name = "dynamic_linking_mode")

    static_linking_mode_feature = feature(name = "static_linking_mode")

    supports_start_end_lib_feature = feature(name = "supports_start_end_lib", enabled = True)

    user_compile_flags_feature = feature(
        name = "user_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.lto_backend,
                    ACTION_NAMES.clif_match,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["%{user_compile_flags}"],
                        iterate_over = "user_compile_flags",
                        expand_if_available = "user_compile_flags",
                    ),
                ],
            ),
        ],
    )

    sysroot_feature = feature(
        name = "sysroot",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.lto_backend,
                    ACTION_NAMES.clif_match,
                    ACTION_NAMES.cpp_link_executable,
                    ACTION_NAMES.cpp_link_dynamic_library,
                    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
                ],
                flag_groups = [
                    flag_group(
                        flags = ["--sysroot=%{sysroot}"],
                        expand_if_available = "sysroot",
                    ),
                ],
            ),
        ],
    )

    unfiltered_compile_flags_feature = feature(
        name = "unfiltered_compile_flags",
        enabled = True,
        flag_sets = [
            flag_set(
                actions = [
                    ACTION_NAMES.assemble,
                    ACTION_NAMES.preprocess_assemble,
                    ACTION_NAMES.linkstamp_compile,
                    ACTION_NAMES.c_compile,
                    ACTION_NAMES.cpp_compile,
                    ACTION_NAMES.cpp_header_parsing,
                    ACTION_NAMES.cpp_module_compile,
                    ACTION_NAMES.cpp_module_codegen,
                    ACTION_NAMES.lto_backend,
                    ACTION_NAMES.clif_match,
                ],
                flag_groups = [
                    flag_group(
                        flags = [
                            "-Wno-builtin-macro-redefined",
                            "-D__DATE__=\"redacted\"",
                            "-D__TIMESTAMP__=\"redacted\"",
                            "-D__TIME__=\"redacted\"",
                            "-fdebug-prefix-map=%{toolchain_path_prefix}=%{debug_toolchain_path_prefix}",
                        ],
                    ),
                ],
            ),
        ],
    )

    fully_static_link_feature = feature(name = "fully_static_link")

    static_linking_mode_nodeps_library_feature = feature(name = "static_linking_mode_nodeps_library")

    if (ctx.attr.cpu == "darwin"):
        default_compile_flags_feature = feature(
            name = "default_compile_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [
                        ACTION_NAMES.assemble,
                        ACTION_NAMES.preprocess_assemble,
                        ACTION_NAMES.linkstamp_compile,
                        ACTION_NAMES.c_compile,
                        ACTION_NAMES.cpp_compile,
                        ACTION_NAMES.cpp_header_parsing,
                        ACTION_NAMES.cpp_module_compile,
                        ACTION_NAMES.cpp_module_codegen,
                        ACTION_NAMES.lto_backend,
                        ACTION_NAMES.clif_match,
                    ],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-no-canonical-prefixes",
                                "-D_FORTIFY_SOURCE=1",
                                "-fstack-protector",
                                "-Wthread-safety",
                                "-Wself-assign",
                                "-fno-omit-frame-pointer",
                                "-fcolor-diagnostics",
                                "-Wall",
                            ],
                        ),
                    ],
                ),
                flag_set(
                    actions = [
                        ACTION_NAMES.assemble,
                        ACTION_NAMES.preprocess_assemble,
                        ACTION_NAMES.linkstamp_compile,
                        ACTION_NAMES.c_compile,
                        ACTION_NAMES.cpp_compile,
                        ACTION_NAMES.cpp_header_parsing,
                        ACTION_NAMES.cpp_module_compile,
                        ACTION_NAMES.cpp_module_codegen,
                        ACTION_NAMES.lto_backend,
                        ACTION_NAMES.clif_match,
                    ],
                    flag_groups = [flag_group(flags = ["-O0", "-DDEBUG"])],
                    with_features = [with_feature_set(features = ["fastbuild"])],
                ),
                flag_set(
                    actions = [
                        ACTION_NAMES.assemble,
                        ACTION_NAMES.preprocess_assemble,
                        ACTION_NAMES.linkstamp_compile,
                        ACTION_NAMES.c_compile,
                        ACTION_NAMES.cpp_compile,
                        ACTION_NAMES.cpp_header_parsing,
                        ACTION_NAMES.cpp_module_compile,
                        ACTION_NAMES.cpp_module_codegen,
                        ACTION_NAMES.lto_backend,
                        ACTION_NAMES.clif_match,
                    ],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-g0",
                                "-O2",
                                "-D_FORTIFY_SOURCE=1",
                                "-DNDEBUG",
                                "-ffunction-sections",
                                "-fdata-sections",
                            ],
                        ),
                    ],
                    with_features = [with_feature_set(features = ["opt"])],
                ),
                flag_set(
                    actions = [
                        ACTION_NAMES.assemble,
                        ACTION_NAMES.preprocess_assemble,
                        ACTION_NAMES.linkstamp_compile,
                        ACTION_NAMES.c_compile,
                        ACTION_NAMES.cpp_compile,
                        ACTION_NAMES.cpp_header_parsing,
                        ACTION_NAMES.cpp_module_compile,
                        ACTION_NAMES.cpp_module_codegen,
                        ACTION_NAMES.lto_backend,
                        ACTION_NAMES.clif_match,
                    ],
                    flag_groups = [flag_group(flags = ["-g"])],
                    with_features = [with_feature_set(features = ["dbg"])],
                ),
                flag_set(
                    actions = [
                        ACTION_NAMES.linkstamp_compile,
                        ACTION_NAMES.cpp_compile,
                        ACTION_NAMES.cpp_header_parsing,
                        ACTION_NAMES.cpp_module_compile,
                        ACTION_NAMES.cpp_module_codegen,
                        ACTION_NAMES.lto_backend,
                        ACTION_NAMES.clif_match,
                    ],
                    flag_groups = [flag_group(flags = ["-std=c++17", "-stdlib=libc++"])],
                ),
            ],
        )
    elif (ctx.attr.cpu == "k8"):
        default_compile_flags_feature = feature(
            name = "default_compile_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = [
                        ACTION_NAMES.assemble,
                        ACTION_NAMES.preprocess_assemble,
                        ACTION_NAMES.linkstamp_compile,
                        ACTION_NAMES.c_compile,
                        ACTION_NAMES.cpp_compile,
                        ACTION_NAMES.cpp_header_parsing,
                        ACTION_NAMES.cpp_module_compile,
                        ACTION_NAMES.cpp_module_codegen,
                        ACTION_NAMES.lto_backend,
                        ACTION_NAMES.clif_match,
                    ],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-no-canonical-prefixes",
                                "-U_FORTIFY_SOURCE",
                                "-fstack-protector",
                                "-fcolor-diagnostics",
                                "-fno-omit-frame-pointer",
                                "-Wall",
                            ],
                        ),
                    ],
                ),
                flag_set(
                    actions = [
                        ACTION_NAMES.assemble,
                        ACTION_NAMES.preprocess_assemble,
                        ACTION_NAMES.linkstamp_compile,
                        ACTION_NAMES.c_compile,
                        ACTION_NAMES.cpp_compile,
                        ACTION_NAMES.cpp_header_parsing,
                        ACTION_NAMES.cpp_module_compile,
                        ACTION_NAMES.cpp_module_codegen,
                        ACTION_NAMES.lto_backend,
                        ACTION_NAMES.clif_match,
                    ],
                    flag_groups = [flag_group(flags = ["-g", "-fstandalone-debug"])],
                    with_features = [with_feature_set(features = ["dbg"])],
                ),
                flag_set(
                    actions = [
                        ACTION_NAMES.assemble,
                        ACTION_NAMES.preprocess_assemble,
                        ACTION_NAMES.linkstamp_compile,
                        ACTION_NAMES.c_compile,
                        ACTION_NAMES.cpp_compile,
                        ACTION_NAMES.cpp_header_parsing,
                        ACTION_NAMES.cpp_module_compile,
                        ACTION_NAMES.cpp_module_codegen,
                        ACTION_NAMES.lto_backend,
                        ACTION_NAMES.clif_match,
                    ],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-g0",
                                "-O2",
                                "-D_FORTIFY_SOURCE=1",
                                "-DNDEBUG",
                                "-ffunction-sections",
                                "-fdata-sections",
                            ],
                        ),
                    ],
                    with_features = [with_feature_set(features = ["opt"])],
                ),
                flag_set(
                    actions = [
                        ACTION_NAMES.linkstamp_compile,
                        ACTION_NAMES.cpp_compile,
                        ACTION_NAMES.cpp_header_parsing,
                        ACTION_NAMES.cpp_module_compile,
                        ACTION_NAMES.cpp_module_codegen,
                        ACTION_NAMES.lto_backend,
                        ACTION_NAMES.clif_match,
                    ],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-std=c++17",
                                "-stdlib=libc++",
                                "-DLIBCXX_USE_COMPILER_RT=YES",
                            ],
                        ),
                    ],
                ),
            ],
        )
    else:
        default_compile_flags_feature = None

    if (ctx.attr.cpu == "k8"):
        default_link_flags_feature = feature(
            name = "default_link_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = all_link_actions,
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-no-canonical-prefixes",
                                "-L%{toolchain_path_prefix}lib",
                                "-l:libc++.a",
                                "-l:libc++abi.a",
                                "-l:libunwind.a",
                                "-rtlib=compiler-rt",
                                "-lpthread",
                                "-ldl",
                                "-lm",
                                "-fuse-ld=lld",
                                "-Wl,--build-id=md5",
                                "-Wl,--hash-style=both",
                                "-Wl,-z,relro,-z,now",
                            ],
                        ),
                    ],
                ),
                flag_set(
                    actions = all_link_actions,
                    flag_groups = [flag_group(flags = ["-Wl,--gc-sections"])],
                    with_features = [with_feature_set(features = ["opt"])],
                ),
            ],
        )
    elif (ctx.attr.cpu == "darwin"):
        default_link_flags_feature = feature(
            name = "default_link_flags",
            enabled = True,
            flag_sets = [
                flag_set(
                    actions = all_link_actions,
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-no-canonical-prefixes",
                                "-lm",
                                "-headerpad_max_install_names",
                            ],
                        ),
                    ],
                ),
                flag_set(
                    actions = all_link_actions,
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-L%{toolchain_path_prefix}lib",
                                "-lc++-static",
                                "-lc++abi-static",
                            ],
                        ),
                    ],
                    with_features = [with_feature_set(features = ["fully_static_link"])],
                ),
                flag_set(
                    actions = [ACTION_NAMES.cpp_link_executable],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-L%{toolchain_path_prefix}lib",
                                "-lc++-static",
                                "-lc++abi-static",
                            ],
                        ),
                    ],
                    with_features = [with_feature_set(features = ["static_linking_mode"])],
                ),
                flag_set(
                    actions = all_link_actions,
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-L%{toolchain_path_prefix}lib",
                                "-lc++-static",
                                "-lc++abi-static",
                            ],
                        ),
                    ],
                    with_features = [
                        with_feature_set(
                            features = ["static_linking_mode_nodeps_library"],
                        ),
                    ],
                ),
                flag_set(
                    actions = [ACTION_NAMES.cpp_link_nodeps_dynamic_library],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-lc++",
                                "-lc++abi",
                                "-undefined",
                                "dynamic_lookup"
                            ]
                        )
                    ],
                ),
                flag_set(
                    actions = [ACTION_NAMES.cpp_link_dynamic_library],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-lc++",
                                "-lc++abi",
                                "-undefined",
                                "dynamic_lookup"
                            ]
                        )
                    ],
                    with_features = [
                        with_feature_set(
                            not_features = ["static_link_cpp_runtimes"],
                        ),
                    ],
                ),
                flag_set(
                    actions = [ACTION_NAMES.cpp_link_executable],
                    flag_groups = [
                        flag_group(
                            flags = [
                                "-lc++",
                                "-lc++abi",
                                "-undefined",
                                "dynamic_lookup"
                            ]
                        )
                    ],
                    with_features = [with_feature_set(features = ["dynamic_linking_mode"])],
                ),
            ],
        )
    else:
        default_link_flags_feature = None

    supports_pic_feature = feature(name = "supports_pic", enabled = True)

    if (ctx.attr.cpu == "k8"):
        features = [
                default_compile_flags_feature,
                default_link_flags_feature,
                coverage_feature,
                supports_dynamic_linker_feature,
                supports_start_end_lib_feature,
                supports_pic_feature,
                objcopy_embed_flags_feature,
                opt_feature,
                dbg_feature,
                user_compile_flags_feature,
                sysroot_feature,
                unfiltered_compile_flags_feature,
            ]
    elif (ctx.attr.cpu == "darwin"):
        features = [
                default_compile_flags_feature,
                default_link_flags_feature,
                framework_paths_feature,
                coverage_feature,
                supports_dynamic_linker_feature,
                objcopy_embed_flags_feature,
                fully_static_link_feature,
                static_linking_mode_feature,
                static_linking_mode_nodeps_library_feature,
                dynamic_linking_mode_feature,
                fastbuild_feature,
                opt_feature,
                dbg_feature,
                user_compile_flags_feature,
                sysroot_feature,
                unfiltered_compile_flags_feature,
            ]
    else:
        fail("Unreachable")

    if (ctx.attr.cpu == "k8"):
        cxx_builtin_include_directories = [
                "%{toolchain_path_prefix}include/c++/v1",
                "%{toolchain_path_prefix}lib/clang/%{llvm_version}/include",
                "%{sysroot_prefix}/include",
                "%{sysroot_prefix}/usr/include",
                "%{sysroot_prefix}/usr/local/include",
            ]
    elif (ctx.attr.cpu == "darwin"):
        cxx_builtin_include_directories = [
                "%{toolchain_path_prefix}include/c++/v1",
                "%{toolchain_path_prefix}lib/clang/%{llvm_version}/include",
                "%{sysroot_prefix}/usr/include",
                "%{sysroot_prefix}/System/Library/Frameworks",
                "/Library/Frameworks",
            ]
    else:
        fail("Unreachable")

    artifact_name_patterns = []

    if (ctx.attr.cpu == "darwin"):
        make_variables = [
            make_variable(
                name = "STACK_FRAME_UNLIMITED",
                value = "-Wframe-larger-than=100000000 -Wno-vla",
            ),
        ]
    elif ctx.attr.cpu == "k8":
        make_variables = []
    else:
        fail("Unreachable")

    if (ctx.attr.cpu == "k8"):
        tool_paths = [
            tool_path(
                name = "ld",
                path = "%{tools_path_prefix}bin/ld.lld",
            ),
            tool_path(
                name = "cpp",
                path = "%{tools_path_prefix}bin/clang-cpp",
            ),
            tool_path(
                name = "dwp",
                path = "%{tools_path_prefix}bin/llvm-dwp",
            ),
            tool_path(
                name = "gcov",
                path = "%{tools_path_prefix}bin/llvm-profdata",
            ),
            tool_path(
                name = "nm",
                path = "%{tools_path_prefix}bin/llvm-nm",
            ),
            tool_path(
                name = "objcopy",
                path = "%{tools_path_prefix}bin/llvm-objcopy",
            ),
            tool_path(
                name = "objdump",
                path = "%{tools_path_prefix}bin/llvm-objdump",
            ),
            tool_path(name = "strip", path = "/usr/bin/strip"),
            tool_path(
                name = "gcc",
                path = "%{tools_path_prefix}bin/clang",
            ),
            tool_path(
                name = "ar",
                path = "%{tools_path_prefix}bin/llvm-ar",
            ),
        ]
    elif (ctx.attr.cpu == "darwin"):
        tool_paths = [
            tool_path(name = "ld", path = "%{tools_path_prefix}bin/ld"),
            tool_path(
                name = "cpp",
                path = "%{tools_path_prefix}bin/clang-cpp",
            ),
            tool_path(
                name = "dwp",
                path = "%{tools_path_prefix}bin/llvm-dwp",
            ),
            tool_path(
                name = "gcov",
                path = "%{tools_path_prefix}bin/llvm-profdata",
            ),
            tool_path(
                name = "nm",
                path = "%{tools_path_prefix}bin/llvm-nm",
            ),
            tool_path(
                name = "objcopy",
                path = "%{tools_path_prefix}bin/llvm-objcopy",
            ),
            tool_path(
                name = "objdump",
                path = "%{tools_path_prefix}bin/llvm-objdump",
            ),
            tool_path(name = "strip", path = "/usr/bin/strip"),
            tool_path(
                name = "gcc",
                path = "%{tools_path_prefix}bin/cc_wrapper.sh",
            ),
            tool_path(name = "ar", path = "/usr/bin/libtool"),
        ]
    else:
        fail("Unreachable")


    out = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.write(out, "Fake executable")
    return [
        cc_common.create_cc_toolchain_config_info(
            ctx = ctx,
            features = features,
            action_configs = action_configs,
            artifact_name_patterns = artifact_name_patterns,
            cxx_builtin_include_directories = cxx_builtin_include_directories,
            toolchain_identifier = toolchain_identifier,
            host_system_name = host_system_name,
            target_system_name = target_system_name,
            target_cpu = target_cpu,
            target_libc = target_libc,
            compiler = compiler,
            abi_version = abi_version,
            abi_libc_version = abi_libc_version,
            tool_paths = tool_paths,
            make_variables = make_variables,
            builtin_sysroot = builtin_sysroot,
            cc_target_os = cc_target_os
        ),
        DefaultInfo(
            executable = out,
        ),
    ]
cc_toolchain_config =  rule(
    implementation = _impl,
    attrs = {
        "cpu": attr.string(mandatory=True, values=["darwin", "k8"]),
    },
    provides = [CcToolchainConfigInfo],
    executable = True,
)
