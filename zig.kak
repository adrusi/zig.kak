# Detection

hook global BufCreate .*[.](zig) %{
    set-option buffer filetype zig
}

# Highlighters

add-highlighter shared/ regions -default code -match-capture zig \
    string    c?"           (?<!\\)(?:\\\\)*" '' \
    mlstring  %{c?\\\\}     $                 '' \
    char      b?'           (?<!\\)'          '' \
    comment   //            $                 ''

add-highlighter shared/zig/string fill string
add-highlighter shared/zig/mlstring fill string
add-highlighter shared/zig/char fill string
add-highlighter shared/zig/comment fill comment

%sh{
    escape='\\(?:[nrt\\'\''"]|x[a-zA-Z0-9]{2}|u[a-zA-Z0-9]{4}|U[a-zA-Z0-9]{6})'
    cat <<KAK
        add-highlighter shared/zig/string regex ${escape} 0:default+b
        add-highlighter shared/zig/char regex ${escape} 0:default+b
        # add-highlighter shared/zig/char regex %{'(?:[^\\]|${escape})([^']+)'} 1:Error
KAK
}

add-highlighter shared/zig/code regex \b(const|var|extern|packed|export|pub|noalias|inline|comptime|nakedcc|stdcallcc|volatile|align|section)\b 0:keyword
add-highlighter shared/zig/code regex \b(struct|enum|union)\b 0:keyword
add-highlighter shared/zig/code regex \b(break|return|continue|asm|defer|errdefer|unreachable|try|catch|async|await|suspend|resume|cancel)\b 0:keyword
add-highlighter shared/zig/code regex \b(if|else|switch|and|or)\b 0:keyword
add-highlighter shared/zig/code regex \b(while|for)\b 0:keyword
add-highlighter shared/zig/code regex \b(fn|use|test)\b 0:keyword

add-highlighter shared/zig/code regex \b(bool|f32|f64|f128|void|noreturn|type|error|promise)\b 0:type
add-highlighter shared/zig/code regex \b(i2|u2|i3|u3|i4|u4|i5|u5|i6|u6|i7|u7|i8|u8|i16|u16|i29|u29|i32|u32|i64|u64|i128|u128|isize|usize)\b 0:type
add-highlighter shared/zig/code regex \b(c_short|c_ushort|c_int|c_uint|c_long|c_ulong|c_longlong|c_ulonglong|c_longdouble|c_void)\b 0:type

add-highlighter shared/zig/code regex \b(null|undefined|this)\b 0:variable
add-highlighter shared/zig/code regex \b(true|false)\b 0:value
add-highlighter shared/zig/code regex \b[0-9]+(?:.[0-9]+)?(?:[eE][+-]?[0-9]+)? 0:value # decimal numeral
add-highlighter shared/zig/code regex \b0x[a-fA-F0-9]+(?:[a-fA-F0-9]+(?:[pP][+-]?[0-9]+)?)? 0:value # hexadecimal numeral
add-highlighter shared/zig/code regex \b0o[0-7]+ 0:value # octal numeral
add-highlighter shared/zig/code regex \b0b[01]+(?:.[01]\+(?:[eE][+-]?[0-9]+)?)?" 0:value # binary numeral

add-highlighter shared/zig/code regex @(addWithOverflow|ArgType|atomicLoad|bitCast|breakpoint)\b 0:builtin
add-highlighter shared/zig/code regex @(alignCast|alignOf|cDefine|cImport|cInclude)\b 0:builtin
add-highlighter shared/zig/code regex @(cUndef|canImplicitCast|clz|cmpxchgWeak|cmpxchgStrong|compileError)\b 0:builtin
add-highlighter shared/zig/code regex @(compileLog|ctz|divExact|divFloor|divTrunc)\b 0:builtin
add-highlighter shared/zig/code regex @(embedFile|export|tagName|TagType|errorName)\b 0:builtin
add-highlighter shared/zig/code regex @(errorReturnTrace|fence|fieldParentPtr|field)\b 0:builtin
add-highlighter shared/zig/code regex @(frameAddress|import|inlineCall|newStackCall|intToPtr|IntType)\b 0:builtin
add-highlighter shared/zig/code regex @(maxValue|memberCount|memberName|memberType)\b 0:builtin
add-highlighter shared/zig/code regex @(memcpy|memset|minValue|mod|mulWithOverflow)\b 0:builtin
add-highlighter shared/zig/code regex @(noInlineCall|offsetOf|OpaqueType|panic|ptrCast)\b 0:builtin
add-highlighter shared/zig/code regex @(ptrToInt|rem|returnAddress|setCold)\b 0:builtin
add-highlighter shared/zig/code regex @(setRuntimeSafety|setEvalBranchQuota|setFloatMode)\b 0:builtin
add-highlighter shared/zig/code regex @(setGlobalLinkage|setGlobalSection|shlExact)\b 0:builtin
add-highlighter shared/zig/code regex @(shlWithOverflow|shrExact|sizeOf|sqrt|subWithOverflow)\b 0:builtin
add-highlighter shared/zig/code regex @(truncate|typeId|typeInfo|typeName|typeOf|atomicRmw)\b 0:builtin

# Commands

define-command -hidden zig-filter-around-selections %{
    # remove trailing whitspace
    try %{ execute-keys -draft -itersel <a-x> s\h+$<ret> d }
}

define-command -hidden zig-indent-on-new-line %[
    evaluate-commands -draft -itersel %[
        # copy comment prefix //
        try %{ execute-keys -draft k <a-x> s^\h*\K///?\h*<ret> y gh j P }
        # preserve indent
        try %{ execute-keys -draft ';' K <a-&> }
        # filter previous line
        try %{ execute-keys -draft k :zig-filter-around-selections<ret> }
        # indent after lines ending with { or (
        try %[ execute-keys -draft k <a-x> <a-k>[{(]\h*$<ret> j <a-gt> ]
    ]
]

define-command -hidden zig-indent-on-closing-curly-brace %[
    evaluate-commands -draft -itersel %[
        # align to opening brace when the closing brace is the only thing on this line
        try %[ execute-keys -draft <a-h> <a-k>^\h+\}$<ret> h m s\A|.\z<ret> 1<a-&> ]
    ]
]

# Initialization

hook -group zig-highlight global WinSetOption filetype=zig %{
    add-highlighter window ref zig
}
hook -group zig-highlight global WinSetOption filetype=(?!zig).* %{
    remove-highlighter window/zig
}

hook global WinSetOption filetype=zig %[
    set-option buffer comment_line '//'
    hook -group zig-hooks window ModeChange insert:.* zig-filter-around-selections
    hook -group zig-indent window InsertChar \n zig-indent-on-new-line
    hook -group zig-indent window InsertChar \} zig-indent-on-closing-curly-brace
]
hook global WinSetOption filetype=(?!zig).* %{
    remove-hooks window zig-indent
    remove-hooks window zig-hooks
}
