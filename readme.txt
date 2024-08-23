;
Name: short-name

;
Title: Human Readable Title (With Short Explanation)

; Presets: shallow < minimal < default < recommended < maximal
 
; projects with given names and preset that is not less 
; should be included and initialized before this one.
Requires: list-of-names[:minimal]

; this package should be included when any on projects 
; with given names and preset that is not less are 
; to be included and initialized before this one.
Augments: list-of-names[:(recommended)|minimal|maximal] ae3/ae3.manuals:recommended

;
Suggests: list-of-names[:(recommended)|minimal|maximal]

;
Declares: list-of-names[:(recommended)|minimal|maximal]

;
Provides: list-of-names[:(recommended)|minimal|maximal]

;
Replaces: list-of-names[:(recommended)|minimal|maximal]

;
Excludes: list-of-names[:(recommended)|minimal|maximal]