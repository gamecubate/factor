! Copyright (C) 2004, 2007 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: classes classes.union words kernel sequences
definitions prettyprint.backend ;
IN: classes.mixin

PREDICATE: union-class mixin-class "mixin" word-prop ;

M: mixin-class reset-class
    { "metaclass" "members" "mixin" } reset-props ;

: redefine-mixin-class ( class members -- )
    dupd define-union-class
    t "mixin" set-word-prop ;

: define-mixin-class ( class -- )
    dup mixin-class? [
        drop
    ] [
        { } redefine-mixin-class
    ] if ;

TUPLE: check-mixin-class mixin ;

: check-mixin-class ( mixin -- mixin )
    dup mixin-class? [
        \ check-mixin-class construct-boa throw
    ] unless ;

: if-mixin-member? ( class mixin true false -- )
    >r >r check-mixin-class 2dup members memq? r> r> if ; inline

: change-mixin-class ( class mixin quot -- )
    [ members swap bootstrap-word ] swap compose keep
    swap redefine-mixin-class ; inline

: add-mixin-instance ( class mixin -- )
    [ 2drop ] [ [ add ] change-mixin-class ] if-mixin-member? ;

: remove-mixin-instance ( class mixin -- )
    [ [ swap remove ] change-mixin-class ] [ 2drop ] if-mixin-member? ;

! Definition protocol implementation ensures that removing an
! INSTANCE: declaration from a source file updates the mixin.
TUPLE: mixin-instance loc class mixin ;

: <mixin-instance> ( class mixin -- definition )
    { set-mixin-instance-class set-mixin-instance-mixin }
    mixin-instance construct ;

M: mixin-instance where mixin-instance-loc ;

M: mixin-instance set-where set-mixin-instance-loc ;

M: mixin-instance synopsis*
    \ INSTANCE: pprint-word
    dup mixin-instance-class pprint-word
    mixin-instance-mixin pprint-word ;

M: mixin-instance definer drop \ INSTANCE: f ;

M: mixin-instance definition drop f ;

M: mixin-instance forget
    dup mixin-instance-class
    swap mixin-instance-mixin
    remove-mixin-instance ;
