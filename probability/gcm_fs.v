Require Import Reals.
From mathcomp Require Import ssreflect ssrfun ssrbool eqtype ssrnat seq.
From mathcomp Require Import choice.
Require Import Reals_ext proba dist convex_choice.
From mathcomp Require Import boolp classical_sets.
From mathcomp Require Import finmap set.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Local Open Scope reals_ext_scope.
Local Open Scope proba_scope.
Local Open Scope convex_scope.

Section misc.
Definition set_of_fset (A : choiceType) (X : {fset A}) : set A :=
  [set a : A | a \in X].
Lemma cset_ext (A : convType) (X Y : {convex_set A}) :
  X = Y <-> (X = Y :> set A).
Proof.
case: X => carX HX; case: Y => carY HY.
split => [-> // | /= H].
destruct H.
congr CSet.mk.
exact/Prop_irrelevance.
Qed.
Lemma hull_monotone (A : convType) (X Y : set A) :
  (X `<=` Y)%classic -> (hull X `<=` hull Y)%classic.
Proof.
move=> H a.
case => n [g [d [H0 H1]]].
exists n, g, d.
split => //.
by eapply subset_trans; first by exact: H0.
Qed.
Lemma hull_eqEsubset (A : convType) (X Y : set A) :
  (X `<=` hull Y)%classic -> (Y `<=` hull X)%classic -> hull X = hull Y.
Proof.
move/hull_monotone; rewrite hullI => H.
move/hull_monotone; rewrite hullI => H0.
by apply/eqEsubset.
Qed.
End misc.

Module PreFSCSet.
Section def.
Variable A : convType.
Record class_of (car : {convex_set A}) : Type := Class {
  supp : {fset A} ;
  _ : car = CSet.mk (convex_hull [set a : A | a \in supp]) ;
}.
Structure t : Type := Pack { car : {convex_set A} ; _ : class_of car }.
End def.
Module Exports.
Notation prefscset := t.
Coercion car : prefscset >-> convex_set_of.
End Exports.
End PreFSCSet.
Export PreFSCSet.Exports.
Section prefscset_lemmas.
Variable A : convType.
Definition prefscset_supp (X : prefscset A) : {fset A} :=
  let: PreFSCSet.Pack _ (PreFSCSet.Class supp _) := X in supp.
Lemma prefscset_hull_supp (X : prefscset A) :
  X = CSet.mk (convex_hull [set a : A | a \in prefscset_supp X]) :> {convex_set A}.
Proof.
case: X => carX [supp H].
apply cset_ext => /=.
by rewrite H.
Qed.

Section canonical.
(*
Definition supp_prefscset (sX : {fset A}) : prefscset A :=
  @PreFSCSet.Pack
    _
    (CSet.mk (convex_hull [set a : A | a \in sX]))
    (PreFSCSet.Class erefl).
Lemma prefscset_suppK : cancel prefscset_supp supp_prefscset.
Proof.
rewrite /supp_prefscset.
case => car [supp H] /=.
Fail congr PreFSCSet.Pack.
Abort.
*)
Definition prefscset_eqMixin : Equality.mixin_of (prefscset A) := @gen_eqMixin (prefscset A).
Canonical prefscset_eqType := Eval hnf in EqType (prefscset A) prefscset_eqMixin.
Definition prefscset_choiceMixin : Choice.mixin_of (prefscset A) := @gen_choiceMixin (prefscset A).
Canonical prefscset_choiceType : choiceType :=
  Eval hnf in Choice.Pack (Choice.Class prefscset_eqMixin prefscset_choiceMixin).
End canonical.
End prefscset_lemmas.

Module FSCSet.
Section def.
Variable A : convType.
Record t : Type := mk {
  car : {convex_set A} ;
  _ : exists supp : {fset A}, car = CSet.mk (convex_hull [set a : A | a \in supp]) ;
}.
End def.
End FSCSet.
Notation fscset := FSCSet.t.
Coercion FSCSet.car : fscset >-> convex_set_of.

Section fscset_lemmas.
Variable (A : convType).

Section canonical.
Definition fscset_eqMixin : Equality.mixin_of (fscset A) := @gen_eqMixin (fscset A).
Canonical fscset_eqType := Eval hnf in EqType (fscset A) fscset_eqMixin.
Definition fscset_choiceMixin : Choice.mixin_of (fscset A) := @gen_choiceMixin (fscset A).
Canonical fscset_choiceType : choiceType :=
  Eval hnf in Choice.Pack (Choice.Class fscset_eqMixin fscset_choiceMixin).
End canonical.

Lemma fscset_ext (X Y : fscset A) : X = Y <-> (X = Y :> {convex_set A}).
Proof.
case: X => carX HX; case: Y => carY HY.
split => [-> // | /= H].
destruct H.
congr FSCSet.mk.
exact/Prop_irrelevance.
Qed.
Lemma fscset_property (X : fscset A) :
exists sX : {fset A}, FSCSet.car X = CSet.mk (convex_hull [set a : A | a \in sX]).
Proof. by case: X.  Qed.
Definition fscset_supp (X : fscset A) : {fset A} :=
(* axiom of choice *)
  let (sX, _) := constructive_indefinite_description (fscset_property X) in sX.
Lemma fscset_hull_supp (X : fscset A) :
  FSCSet.car X = CSet.mk (convex_hull [set a : A | a \in fscset_supp X]).
Proof. rewrite /fscset_supp. by case: (cid (fscset_property X)). Qed.
Lemma fscset_hull_supp' (X : fscset A) :
  X = CSet.mk (convex_hull [set a : A | a \in fscset_supp X]) :> {convex_set A}.
Proof. by rewrite fscset_hull_supp. Qed.

Lemma fscset_supp0E' (X : fscset A) :
  (fscset_supp X = fset0) <-> (X = cset0 _ :> {convex_set A}).
Proof.
split.
- move/(congr1 (fun Y => CSet.mk (convex_hull [set a : A | a \in Y]))).
  rewrite -fscset_hull_supp => ->.
  rewrite cset_ext /=.
  apply/eqP; rewrite hull_eq0; apply/eqP.
  apply funext => a.
  by rewrite inE falseE.
- move => H; apply/eqP; move/eqP : H.
  apply contraLR.
  case/fset0Pn => a Ha.
  apply/eqP; rewrite fscset_hull_supp cset_ext /=; apply/eqP.
  rewrite hull_eq0.
  apply/set0P.
  by exists a.
Qed.
Lemma fscset_supp0E (X : fscset A) :
  (fscset_supp X == fset0) = (X == cset0 _ :> {convex_set A}).
Proof. apply/eqP/eqP; by rewrite fscset_supp0E'. Qed.
End fscset_lemmas.

Module NECSet.
Section def.
Local Open Scope classical_set_scope.
Local Open Scope proba_scope.
Variable A : convType.
Record t : Type := mk {
  car : fscset A ;
  _ : car != cset0 _ :> {convex_set A}}.
End def.
End NECSet.
Notation necset := NECSet.t.
Coercion NECSet.car : necset >-> fscset.

Section necset_canonical.
Variable (A : convType).

Canonical necset_subType := [subType for @NECSet.car A].
Canonical necset_predType :=
  Eval hnf in mkPredType (fun t : necset A => (fun x => x \in FSCSet.car (NECSet.car t))).
Definition necset_eqMixin := Eval hnf in [eqMixin of (@necset A) by <:].
Canonical necset_eqType := Eval hnf in EqType (necset A) necset_eqMixin.
Definition necset_choiceMixin : Choice.mixin_of (necset A) := @gen_choiceMixin (necset A).
Canonical necset_choiceType : choiceType :=
  Eval hnf in Choice.Pack (Choice.Class necset_eqMixin necset_choiceMixin).
End necset_canonical.

(* non-empty finitely supported convex sets of distributions *)
Notation "{ 'csdist+' T }" := (necset (Dist_convType T)) (format "{ 'csdist+'  T }") : convex_scope.

Section necset_lemmas.
Variable A : convType.

Lemma necset_ext (X Y : necset A) : X = Y <-> (X = Y :> {convex_set A}).
Proof.
case: X => carX HX; case: Y => carY HY.
split => [-> // | /= H].
move/fscset_ext: H => H.
destruct H.
congr NECSet.mk.
exact/Prop_irrelevance.
Qed.
Definition necset_supp (X : necset A) : {fset A} := fscset_supp X.
Lemma necset_hull_supp (X : necset A) :
  X = CSet.mk (convex_hull [set a : A | a \in necset_supp X]) :> {convex_set A}.
Proof. by rewrite fscset_hull_supp. Qed.
Lemma necset_neq0 (X : necset A) : X != cset0 _ :> {convex_set A}.
Proof. by case: X. Qed.
Lemma necset_supp_neq0 (X : necset A) : necset_supp X != fset0.
Proof. by rewrite fscset_supp0E necset_neq0. Qed.
End necset_lemmas.

Module necset_convType.
Section def.
Variable A : convType.
Let necset := necset A.
Local Open Scope bool_scope.
Local Open Scope fset_scope.
Definition conv_supp (X Y : necset) (p : prob) : {fset A} :=
  (fun xy => xy.1 <| p |> xy.2) @` (necset_supp X `*` necset_supp Y).
Lemma conv_supp1 X Y : conv_supp X Y `Pr 1 = fscset_supp X.
Proof.
case: X => carX HX; case: Y => carY HY.
move/idP: (HY); rewrite -{1}fscset_supp0E; case/fset0Pn => y yY.
apply/eqP; rewrite eqEfsubset; apply/andP; split; apply/fsubsetP => a.
- move/imfsetP => -[xy /=]; by rewrite conv1 in_fsetM => /andP [Hx _] ->.
- move => aX; apply/imfsetP; exists (a,y); last by rewrite conv1.
  by rewrite inE aX yY .
Qed.
(* NB: It's impossible to obtain conv_suppmm. Because of this, the type of
   (finite) powersets of a convType cannot be a convType again. We need to
   take hulls. *)
Lemma conv_suppC X Y p : conv_supp X Y p = conv_supp Y X `Pr p.~.
Proof.
apply/eqP.
rewrite /conv_supp eqEfsubset.
apply/andP; split; apply/fsubsetP => a /imfsetP [[x y]]; rewrite !inE /= => /andP [H0 H1] ->; [rewrite convC | rewrite -convC]; change y with (y, x).1; change x with (y, x).2; rewrite in_imfset //= inE /=; by apply/andP.
Qed.
Definition pre_conv (X Y : necset) (p : prob) : fscset A.
apply (@FSCSet.mk _ (CSet.mk (convex_hull [set a : A | a \in conv_supp X Y p]))).
exists (conv_supp X Y p).
exact: erefl.
Defined.
Lemma conv_supp_neq0 X Y p : conv_supp X Y p != fset0.
Proof.
apply/fset0Pn.
case/fset0Pn: (necset_supp_neq0 X) => x xX.
case/fset0Pn: (necset_supp_neq0 Y) => y yY.
exists ((x,y).1 <|p|> (x,y).2).
by rewrite in_imfset // inE xX yY.
Qed.
Lemma pre_conv_neq0 X Y p : pre_conv X Y p != cset0 _ :> {convex_set A}.
Proof.
apply/eqP; move/cset_ext => /=; apply/eqP.
rewrite hull_eq0.
case/fset0Pn : (conv_supp_neq0 X Y p) => a Ha.
rewrite set0P.
by exists a.
Qed.
Definition conv (X Y : necset) p : necset := NECSet.mk (pre_conv_neq0 X Y p).
Lemma conv1 X Y : conv X Y `Pr 1 = X.
Proof. by rewrite necset_ext /= [in RHS]fscset_hull_supp conv_supp1. Qed.
Lemma convmm X p : conv X X p = X.
Proof.
case: X => carX HX.
rewrite necset_ext /= [in RHS]fscset_hull_supp cset_ext /=.
apply hull_eqEsubset => a.
- rewrite /conv_supp /necset_supp.
  case/imfsetP => -[a0 a1] /=.
  rewrite inE /= => /andP [Ha0 Ha1] ->.
  set Z:= ([set a : A | a \in fscset_supp carX])%classic.
  have -> : Z = (Z `|` Z)%classic by rewrite setUid.
  by rewrite -in_setE mem_hull_setU // /Z inE asboolE.
- move=> H.
  rewrite -in_setE; apply hull_mem; rewrite inE asboolE /conv_supp.
  by apply/imfsetP; exists (a, a); rewrite /= ?convmm // inE /=; apply/andP; split.
Qed.
Lemma convC X Y p : conv X Y p = conv Y X `Pr p.~.
Proof. by rewrite /conv necset_ext /= cset_ext /= conv_suppC. Qed.
Lemma convA p q X Y Z :
  conv X (conv Y Z q) p = conv (conv X Y [r_of p, q]) Z [s_of p, q].
Proof.
rewrite /conv necset_ext /= /conv_supp cset_ext /=.
apply hull_eqEsubset => a /imfsetP [[a0 a1]] /=; rewrite inE /= => /andP [Ha0 Ha1] ->.
Admitted.

Definition convMixin : ConvexSpace.class_of [choiceType of necset]
  := @ConvexSpace.Class _ conv conv1 convmm convC convA.

End def.
End necset_convType.
Canonical necset_convType A := ConvexSpace.Pack (necset_convType.convMixin A).

(* non-empty convex sets of distributions *)
Notation "{ 'csdist+' T }" := (necset (Dist_convType T)) (format "{ 'csdist+'  T }") : convex_scope.

Section P_delta.
(* P = necset \o Dist, where
   - Dist is the free convex space functor, and
   - necset is the finitely-supported convex power functor. *)
Definition P : choiceType -> choiceType := fun x => [choiceType of necset (Dist_convType x)].

(* we now prove that P forms a convex space *)
Section P_convex_space.
Variable A : choiceType.
Axiom Conv2Pd : forall A : choiceType, P A -> P A -> Reals_ext.Prob.t -> P A.
Axiom Conv2Pconv1 : forall (A : choiceType) a b, @Conv2Pd A a b (`Pr 1) = a.
Axiom Conv2Pconvmm : forall (A : choiceType) a p, @Conv2Pd A a a p = a.
Axiom Conv2PconvC : forall (A : choiceType) a b p, @Conv2Pd A a b p = @Conv2Pd A b a (`Pr p.~).
Axiom Conv2PconvA' : forall (A : choiceType) p q a b c,
  @Conv2Pd A a (@Conv2Pd A b c q) p = @Conv2Pd A (@Conv2Pd A a b ([r_of p, q])) c ([s_of p, q]).
Definition P_convMixin :=
  @ConvexSpace.Class (P A) (@Conv2Pd A)
  (@Conv2Pconv1 A)
  (@Conv2Pconvmm A)
  (@Conv2PconvC A)
  (@Conv2PconvA' A).
Canonical P_convType := ConvexSpace.Pack P_convMixin.
End P_convex_space.

Canonical conv_lattType C := @SemiLattice.Pack (P_convType C) (P_semiLattClass _).

Definition PD := P \o Dist.

Section monad_mu.

Axiom eps0: forall {C : convType}, Dist C -> C (* p.164 *).
(* will be Convn? TODO  *)
Axiom eps1 : forall {L : semiLattType}, P L -> L (* just flattening of lattice joins? preserves oplus and convex hull*).
(* for an affine function f, returns a function F#f that to each convex set of dist returns its image by f, f needs to be affine *)
Axiom F : forall {X Y : convType}, (X -> Y) -> P X -> P Y.
Axiom F_preserves_affine : forall (X Y : convType) (f : X -> Y),
    affine_function f -> affine_function (F f).

Definition mu {T : choiceType} : PD (PD T) -> PD T := eps1 \o F eps0.

End monad_mu.

End P_delta.
