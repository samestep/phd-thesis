(* OCaml 5 effect handlers: `Pool` is performed, and the nearest handler answers. *)
open Effect
open Effect.Deep

type node = Lit of int | Add of int * int | Mul of int * int
type _ Effect.t += Pool : node Dynarray.t Effect.t

let node n = let p = perform Pool in Dynarray.add_last p n; Dynarray.length p - 1
let lit n = node (Lit n)
let add l r = node (Add (l, r))
let mul l r = node (Mul (l, r))

let rec eval e =
  match Dynarray.get (perform Pool) e with
  | Lit n -> n
  | Add (l, r) -> eval l + eval r
  | Mul (l, r) -> eval l * eval r

let with_pool f =
  let p = Dynarray.create () in
  try_with f ()
    { effc = fun (type a) (eff : a Effect.t) ->
        match eff with
        | Pool -> Some (fun (k : (a, _) continuation) -> continue k p)
        | _ -> None }

let () =
  with_pool (fun () ->
      let e = mul (add (lit 1) (lit 2)) (add (lit 3) (lit 4)) in
      Printf.printf "%d\n" (eval e);
      with_pool (fun () -> Printf.printf "%d\n" (eval (add (lit 4) (lit 4))));
      Printf.printf "%d\n" (eval e))
