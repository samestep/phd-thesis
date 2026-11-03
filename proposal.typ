#import "snippet.typ": diff, listings, snippet

#set raw(syntaxes: "syntaxes/moss.sublime-syntax")

#show: listings

#let citet(key) = cite(key, form: "prose")

#align(center)[
  = Ambient Polymorphism

  Sam Estep
]

= Abstract

...

= Introduction

PostgreSQL 11.22 (#cite(<postgresql2023>, form: "year")) returns zero for the following query @simon1989:

#snippet("postgres/NumAcc4.sql")

Why?

#snippet("vendor/postgres/src/backend/utils/adt/float.c", from: "Datum\nfloat8_stddev_samp(")

#bibliography("refs.yml", style: "chicago-author-date")
