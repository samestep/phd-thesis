(* A functor over a signature for real numbers, applied to OCaml's [float]
   and to a double-double module written here: the same source as the
   OCaml [rerun] example, and the same changes to the routine (written
   inside the functor, against [R]'s operations, with every literal built
   from [R]: [of_int 100000002 / of_int 10], since OCaml has no overloaded
   literals). What OxCaml adds is the compiler: flambda 2 compiles a copy of
   the functor's body per application, and in [Wide]'s copy of [sd] every
   arithmetic operation is a direct call to [Double_double]'s, where
   OCaml's single shared copy calls them indirectly. That is an
   optimization, not a guarantee the language makes, and the choice of
   [R] is still made by name at each use ([Plain.report], [Wide.report]),
   not for a caller's dynamic extent. OxCaml's own mechanisms for
   specializing code ([ppx_template]'s [@kind] and [@mode] instances)
   range over layouts and modes, not over types like [R.t]. *)

module type REAL = sig
  type t

  val of_int : int -> t
  val ( + ) : t -> t -> t
  val ( - ) : t -> t -> t
  val ( * ) : t -> t -> t
  val ( / ) : t -> t -> t
  val ( <= ) : t -> t -> bool
  val sqrt : t -> t
  val round : t -> int
end

module Double : REAL with type t = float = struct
  type t = float

  (* To the nearest integer, ties to even. *)
  let round x =
    if Float.abs (x -. Float.trunc x) = 0.5 then
      Float.to_int (2. *. Float.round (x /. 2.))
    else Float.to_int (Float.round x)

  let of_int = Float.of_int
  let ( + ) = Float.add
  let ( - ) = Float.sub
  let ( * ) = Float.mul
  let ( / ) = Float.div
  let ( <= ) (a : float) b = a <= b
  let sqrt = Float.sqrt
end

(* [hi + lo], with [|lo|] at most half an ulp of [hi]: 106 bits. *)
module Double_double : sig
  include REAL

  val of_float : float -> t
end = struct
  type t = { hi : float; lo : float }

  let of_float x = { hi = x; lo = 0. }
  let of_int n = of_float (Float.of_int n)

  let quick_two_sum s e =
    let hi = s +. e in
    { hi; lo = e -. (hi -. s) }

  let two_sum a b =
    let s = a +. b in
    let bb = s -. a in
    { hi = s; lo = (a -. (s -. bb)) +. (b -. bb) }

  let two_prod a b =
    let p = a *. b in
    { hi = p; lo = Float.fma a b (-.p) }

  let ( + ) a b =
    let s = two_sum a.hi b.hi in
    let t = two_sum a.lo b.lo in
    let u = quick_two_sum s.hi (s.lo +. t.hi) in
    quick_two_sum u.hi (u.lo +. t.lo)

  let ( - ) a b = a + { hi = -.b.hi; lo = -.b.lo }

  let ( * ) a b =
    let p = two_prod a.hi b.hi in
    quick_two_sum p.hi (p.lo +. ((a.hi *. b.lo) +. (a.lo *. b.hi)))

  let ( / ) a b =
    let q1 = a.hi /. b.hi in
    let r1 = a - (b * of_float q1) in
    let q2 = r1.hi /. b.hi in
    let r2 = r1 - (b * of_float q2) in
    let q3 = r2.hi /. b.hi in
    quick_two_sum q1 q2 + of_float q3

  let sqrt a =
    if a.hi <= 0. then of_float (Float.sqrt a.hi)
    else
      let x = Float.sqrt a.hi in
      let r = a - two_prod x x in
      quick_two_sum x (r.hi /. (x +. x))

  let round a =
    let n = Double.round a.hi in
    let d = a.hi -. Float.of_int n in
    if d = 0.5 && a.lo > 0. then Int.add n 1
    else if d = -0.5 && a.lo < 0. then Int.sub n 1
    else n

  (* Last, so as not to hide [float]'s [<=] above. *)
  let ( <= ) a b = a.hi < b.hi || (a.hi = b.hi && a.lo <= b.lo)
end

module Stats (R : REAL) = struct
  (* NIST StRD NumAcc4: 10000000.2, then 10000000.1 and 10000000.3 in turn. *)
  let readings () =
    let ten = R.of_int 10 in
    Array.init 1001 (fun i ->
        if i = 0 then R.(of_int 100000002 / ten)
        else if i mod 2 = 1 then R.(of_int 100000001 / ten)
        else R.(of_int 100000003 / ten))

  (* The schoolbook one-pass formula, as PostgreSQL's [stddev] computed it
     until version 12, clamp included. *)
  let sd xs =
    let open R in
    let n = ref (of_int 0) and sum = ref (of_int 0) and sum_sq = ref (of_int 0) in
    Array.iter
      (fun x ->
        n := !n + of_int 1;
        sum := !sum + x;
        sum_sq := !sum_sq + (x * x))
      xs;
    let numerator = (!n * !sum_sq) - (!sum * !sum) in
    if numerator <= of_int 0 then of_int 0
    else sqrt (numerator / (!n * (!n - of_int 1)))

  let show sd = Printf.printf "%d\n" (R.round R.(sd * of_int 1000000000))
  let report () = show (sd (readings ()))
end

module Plain = Stats (Double)
module Wide = Stats (Double_double)

let () =
  Plain.report ();
  let xs = Plain.readings () in
  Wide.show (Wide.sd (Array.map Double_double.of_float xs));
  Wide.report ()
