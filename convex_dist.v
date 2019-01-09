From mathcomp Require Import ssreflect ssrbool ssrfun eqtype ssrnat seq div.
From mathcomp Require Import choice fintype finfun bigop prime binomial ssralg.
From mathcomp Require Import finset fingroup finalg matrix.
Require Import Reals Fourier Ranalysis_ext Lra.
Require Import ssrR Reals_ext logb ssr_ext ssralg_ext bigop_ext Rbigop proba.
Require Import entropy proba cproba convex binary_entropy_function.
Require Import log_sum divergence.

Set Implicit Arguments.
Unset Strict Implicit.
Import Prenex Implicits.

(* wip: concavity of relative entropy and of mutual information *)

Local Open Scope proba_scope.
Local Open Scope reals_ext_scope.

Section convex_dist.
Section def.
Variables (A : finType) (f : dist A -> R).
Definition convex_dist := forall (p q : dist A) (t : R) (Ht : 0 <= t <= 1),
  f (ConvexDist.d p q Ht) <= t * f p + t.~ * f q.
End def.
End convex_dist.

Section concave_dist.
Section def.
Variables (A : finType) (f : dist A -> R).
Definition concave_dist := convex_dist (fun x => - f x).
End def.
Section prop.
Variables (A : finType) (f : dist A -> R).
Lemma convex_distN : concave_dist f -> convex_dist (fun x => - f x).
Proof. by []. Qed.
Lemma concave_distN : convex_dist f -> concave_dist (fun x => - f x).
Proof.
move=> H; rewrite /concave_dist (_ : (fun x => - - f x) = f) //.
apply FunctionalExtensionality.functional_extensionality => ?; by rewrite oppRK.
Qed.
End prop.
Section prop2.
Variables (A : finType).
Lemma convex_distB (f g : dist A -> R) :
  convex_dist f -> concave_dist g -> convex_dist (fun x => f x - g x).
Proof.
move=> H1 H2 p q t t01; rewrite 2!mulRBr addRAC addRA.
move: (H1 p q t t01) => {H1}H1.
rewrite -addR_opp -(addRA (_ + _)); apply leR_add => //; by rewrite -2!mulRN addRC.
Qed.
Lemma concave_distB (f g : dist A -> R) :
  concave_dist f -> convex_dist g -> concave_dist (fun x => f x - g x).
Proof.
move=> H1 H2.
rewrite (_ : (fun _ => _) = (fun x => - (g x - f x))); last first.
  apply FunctionalExtensionality.functional_extensionality => x; by rewrite oppRB.
exact/concave_distN/convex_distB.
Qed.
End prop2.
End concave_dist.

Section affine_dist.
Section def.
Variables (A : finType) (f : dist A -> R).
Definition affine_dist := convex_dist f /\ concave_dist f.
End def.
Section prop.
Variables (A : finType) (P : dist A -> Prop) (f : dist A -> R).
Lemma affine_distP : affine_dist f <-> forall p q t (t01 : 0 <= t <= 1),
  f (ConvexDist.d p q t01) = t * f p + t.~ * f q.
Proof.
split => [[H1 H2] p q t t01| H]; last first.
  split.
  - move=> p q t t01; rewrite H //; exact/leRR.
  - move=> p q t t01; rewrite H // oppRD -!mulRN; exact/leRR.
rewrite eqR_le; split; first exact/H1.
rewrite -[X in X <= _](oppRK _) leR_oppl oppRD -2!mulRN; exact/H2.
Qed.
Lemma affine_distN : affine_dist f -> affine_dist (fun x => - f x).
Proof. case=> H1 H2; split => //; exact/concave_distN. Qed.
End prop.
End affine_dist.

Section convex_dist_pair.
Variables (A : finType) (f : dist A -> dist A -> R).
Definition convex_dist_pair := forall (p1 p2 q1 q2 : dist A) (t : R) (Ht : 0 <= t <= 1),
  p1 << q1 -> p2 << q2 ->
  f (ConvexDist.d p1 p2 Ht) (ConvexDist.d q1 q2 Ht) <=
  t * f p1 q1 + t.~ * f p2 q2.
End convex_dist_pair.
Definition concave_dist_pair (A : finType) (f : dist A -> dist A -> R) :=
  convex_dist_pair (fun a b => - f a b).

Local Open Scope entropy_scope.

Section entropy_log_div.
Variables (A : finType) (p : dist A) (n : nat) (A_not_empty : #|A| = n.+1).
Let u := Uniform.d A_not_empty.

Local Open Scope divergence_scope.

Lemma entropy_log_div : entropy p = log #|A|%:R - D(p || u).
Proof.
rewrite /entropy /div.
evar (RHS : A -> R).
have H : forall a : A, p a * log (p a / u a) = RHS a.
  move => a.
  move : (pos_f_ge0 (pmf p) a) => [H|H].
  - rewrite Uniform.dE.
    change (p a * log (p a / / #|A|%:R)) with (p a * log (p a * / / #|A|%:R)).
    have H0 : 0 < #|A|%:R by rewrite A_not_empty ltR0n.
    have H1 : #|A|%:R <> 0 by apply gtR_eqF.
    rewrite invRK // logM // mulRDr.
    by instantiate (RHS := fun a => p a * log (p a) + p a * log #|A|%:R).
  - by rewrite /RHS -H /= 3!mul0R add0R.
have H0 : \rsum_(a in A) p a * log (p a / u a) = \rsum_(a in A) RHS a.
  move : H; rewrite /RHS => H.
  exact: eq_bigr.
rewrite H0 /RHS.
rewrite big_split /=.
rewrite -big_distrl /=.
rewrite (pmf1 p) mul1R.
by rewrite -addR_opp oppRD addRC -addRA Rplus_opp_l addR0.
Qed.
End entropy_log_div.

(* convexity of relative entropy *)
Section divergence_convex.
Variables (A : finType) (n : nat) (A_not_empty : #|A| = n.+1).

Local Open Scope divergence_scope.

(* thm 2.7.2 *)
Lemma div_convex : convex_dist_pair (@div A).
Proof.
(* TODO: clean *)
move=> p1 p2 q1 q2 t t01 pq1 pq2.
rewrite 2!big_distrr /= -big_split /= /div.
rewrite rsum_setT [in X in _ <= X]rsum_setT.
apply ler_rsum => a _.
rewrite 2!ConvexDist.dE.
case/boolP : (q2 a == 0) => [|] q2a0.
  rewrite (eqP q2a0) !(mul0R,mulR0,add0R).
  have p2a0 : p2 a == 0.
    apply/eqP.
    move/dominatesP in pq2.
    exact/pq2/eqP.
  rewrite (eqP p2a0) !(mulR0,addR0,mul0R).
  case/boolP : (q1 a == 0) => [|] q1a0.
    have p1a0 : p1 a == 0.
      apply/eqP.
      move/dominatesP in pq1.
      exact/pq1/eqP.
    rewrite (eqP p1a0) !(mulR0,mul0R); exact/leRR.
  case/boolP : (t == 0) => [/eqP ->|t0].
    rewrite !mul0R; exact/leRR.
  apply/Req_le.
  rewrite mulRA; congr (_ * _ * log _).
  field.
  split; exact/eqP.
case/boolP : (q1 a == 0) => [|] q1a0.
  rewrite (eqP q1a0) !(mul0R,mulR0,add0R).
  have p1a0 : p1 a == 0.
    apply/eqP.
    move/dominatesP in pq1.
    exact/pq1/eqP.
  rewrite (eqP p1a0) !(mulR0,addR0,mul0R,add0R).
  case/boolP : (t.~ == 0) => [/eqP ->|t0].
    rewrite !mul0R; exact/leRR.
  apply/Req_le.
  rewrite mulRA; congr (_ * _ * log _).
  field.
  split; exact/eqP.
set h : dist A -> dist A -> 'I_2 -> R := fun p1 p2 => [eta (fun=> 0) with
  ord0 |-> t * p1 a, lift ord0 ord0 |-> t.~ * p2 a].
have hdom : ((h p1 p2) << (h q1 q2)).
  apply/dominatesP => i.
  rewrite /h /=; case: ifPn => _.
  rewrite mulR_eq0 => -[->|/eqP].
  by rewrite mul0R.
  by rewrite (negbTE q1a0).
  case: ifPn => // _.
  rewrite mulR_eq0 => -[->|/eqP].
  by rewrite mul0R.
  by rewrite (negbTE q2a0).
set f : 'I_2 -> R := h p1 p2.
set g : 'I_2 -> R := h q1 q2.
have h0 : forall p1 p2 i, 0 <= h p1 p2 i.
  move=> ? ? ?; rewrite /h /=.
  case: ifPn => [_ | _]; first by apply mulR_ge0; [case: t01|exact/dist_ge0].
  case: ifPn => [_ |  _]; [|exact/leRR].
  apply/mulR_ge0; [apply/onem_ge0; by case: t01|exact/dist_ge0].
move: (@log_sum _ setT (mkPosFun (h0 p1 p2)) (mkPosFun (h0 q1 q2)) hdom).
rewrite /=.
have rsum_setT' : forall (f : 'I_2 -> R),
  \rsum_(i < 2) f i = \rsum_(i in [set: 'I_2]) f i.
  move=> f0; by apply eq_bigl => i; rewrite inE.
rewrite -!rsum_setT' !big_ord_recl !big_ord0 !addR0.
rewrite /h /=; move/leR_trans; apply.
apply/Req_le; congr (_ + _).
  case/boolP : (t == 0) => [/eqP ->|t0]; first by rewrite !mul0R.
  rewrite mulRA; congr (_ * _ * log _).
  field.
  split; exact/eqP.
case/boolP : (t.~ == 0) => [/eqP ->|t1]; first by rewrite !mul0R.
rewrite mulRA; congr (_ * _ * log _).
field.
split; exact/eqP.
Qed.

End divergence_convex.

Section entropy_concave.
Variable (A : finType).
Hypothesis A_not_empty : (0 < #|A|)%nat.
Let A_not_empty' : #|A| = #|A|.-1.+1.
Proof. by rewrite prednK. Qed.
Let u : {dist A} := Uniform.d A_not_empty'.

Local Open Scope divergence_scope.

(* thm 2.7.3 *)
Lemma entropy_concave : concave_dist (fun P : dist A => `H P).
Proof.
rewrite /concave_dist => p q t t01.
rewrite !(entropy_log_div _ A_not_empty') /=.
rewrite oppRD oppRK 2!mulRN mulRDr mulRN mulRDr mulRN oppRD oppRK oppRD oppRK.
rewrite addRCA !addRA -2!mulRN -mulRDl (addRC _ t) onemKC mul1R -addRA leR_add2l.
move: (div_convex t01 (dom_by_uniform p A_not_empty') (dom_by_uniform q A_not_empty')).
by rewrite ConvexDist.idempotent.
Qed.

End entropy_concave.

Module entropy_concave_alternative_proof_binary_case.

Lemma Rnonneg_convex : convex_interval (fun x => 0 <= x).
Proof.
rewrite /convex_interval => x y t Hx Hy Ht.
apply addR_ge0; apply/mulR_ge0 => //; [by case: Ht | apply/onem_ge0; by case: Ht].
Qed.

Definition Rnonneg_interval := mkInterval Rnonneg_convex.

Lemma open_interval_convex (a b : R) (Hab : a < b) : convex_interval (fun x => a < x < b).
Proof.
have onem_01 : 0.~ = 1  by rewrite onem_eq1.
have onem_10 : 1.~ = 0  by rewrite onem_eq0.
move => x y t [Hxa Hxb] [Hya Hyb] [[Haltt|Haeqt] [Htltb|Hteqb]]
 ; [
 | by rewrite {Haltt} Hteqb onem_10 mul0R addR0 mul1R; apply conj
 | by rewrite {Htltb} -Haeqt onem_01 mul0R add0R mul1R; apply conj
 | by rewrite Hteqb in Haeqt; move : Rlt_0_1 => /Rlt_not_eq].
have H : 0 < t.~ by apply onem_gt0.
apply conj.
- rewrite -[X in X < t * x + t.~ * y]mul1R -(onemKC t) mulRDl.
  by apply ltR_add; rewrite ltR_pmul2l.
- rewrite -[X in _ + _ < X]mul1R -(onemKC t) mulRDl.
  by apply ltR_add; rewrite ltR_pmul2l.
Qed.

Lemma open_unit_interval_convex : convex_interval (fun x => 0 < x < 1).
Proof. apply /open_interval_convex /Rlt_0_1. Qed.

Definition open_unit_interval := mkInterval open_unit_interval_convex.

Lemma pderivable_H2 : pderivable H2 (mem_interval open_unit_interval).
Proof.
move=> x /= [Hx0 Hx1].
apply derivable_pt_plus.
apply derivable_pt_opp.
apply derivable_pt_mult; [apply derivable_pt_id|apply derivable_pt_Log].
assumption.
apply derivable_pt_opp.
apply derivable_pt_mult.
apply derivable_pt_Rminus.
apply derivable_pt_comp.
apply derivable_pt_Rminus.
apply derivable_pt_Log.
lra.
(* NB : transparent definition is required to proceed with a forward proof, later in concavity_of_entropy_x_le_y *)
Defined.

Lemma expand_interval_closed_to_open a b c d :
  a < b -> b < c -> c < d -> forall x, b <= x <= c -> a < x < d.
Proof.
  move => Hab Hbc Hcd x [Hbx Hxc].
  by apply conj; [eapply Rlt_le_trans|eapply Rle_lt_trans]; [exact Hab|exact Hbx|exact Hxc|exact Hcd].
Qed.

Lemma expand_internal_closed_to_closed a b c d :
  a <= b -> b < c -> c <= d -> forall x, b <= x <= c -> a <= x <= d.
Proof.
  move => Hab Hbc Hcd x [Hbx Hxc].
  by apply conj; [eapply Rle_trans|eapply Rle_trans]; [exact Hab|exact Hbx|exact Hxc|exact Hcd].
Qed.

Lemma expand_interval_open_to_open a b c d :
  a < b -> b < c -> c < d -> forall x, b < x < c -> a < x < d.
Proof.
  move => Hab Hbc Hcd x [Hbx Hxc].
  by apply conj; [eapply Rlt_trans|eapply Rlt_trans]; [exact Hab|exact Hbx|exact Hxc|exact Hcd].
Qed.

Lemma expand_interval_open_to_closed a b c d :
  a <= b -> b < c -> c <= d -> forall x, b < x < c -> a <= x <= d.
Proof.
  move => Hab Hbc Hcd x [Hbx Hxc].
  by apply conj; [eapply Rle_trans|eapply Rle_trans]; [exact Hab|apply or_introl; exact Hbx|apply or_introl; exact Hxc|exact Hcd].
Qed.

Lemma concavity_of_entropy_x_le_y x y t :
      open_unit_interval x -> open_unit_interval y -> 0 <= t <= 1 -> x < y
      -> concavef_leq H2 x y t.
Proof.
  move => [H0x Hx1] [H0y Hy1] [H0t Ht1] Hxy.
  eapply second_derivative_convexf.
  Unshelve.
  - Focus 4. done.
  - Focus 4. done.
  - Focus 4.
    move => z Hz.
    by apply /derivable_pt_opp /pderivable_H2 /(@expand_interval_closed_to_open 0 x y 1).
  - Focus 4.
    exact (fun z => log z - log (1 - z)).
  - Focus 4.
    move => z [Hxz Hzy].
    apply derivable_pt_minus.
    apply derivable_pt_Log.
    apply (ltR_leR_trans H0x Hxz).
    apply derivable_pt_comp.
    apply derivable_pt_Rminus.
    apply derivable_pt_Log.
    apply subR_gt0.
    by apply (leR_ltR_trans Hzy Hy1).
  - Focus 4.
    exact (fun z => / (z * (1 - z) * ln 2)).
  -
    move => z Hz.
    rewrite derive_pt_opp.
    set (H := expand_interval_closed_to_open _ _ _ _).
    rewrite /pderivable_H2.
    case H => [H0z Hz1].
    rewrite derive_pt_plus.
    rewrite 2!derive_pt_opp.
    rewrite 2!derive_pt_mult.
    rewrite derive_pt_id derive_pt_comp 2!derive_pt_Log /=.
    rewrite mul1R mulN1R mulRN1.
    rewrite [X in z * X]mulRC [X in (1 - z) * - X]mulRC mulRN 2!mulRA.
    rewrite !mulRV; [|by apply /eqP; move => /subR0_eq /gtR_eqF|by apply /eqP /gtR_eqF].
    rewrite mul1R -2!oppRD oppRK.
    by rewrite [X in X + - _]addRC oppRD addRA addRC !addRA Rplus_opp_l add0R addR_opp.
  -
    move => z [Hxz Hzy].
    rewrite derive_pt_minus.
    rewrite derive_pt_comp 2!derive_pt_Log /=.
    rewrite mulRN1 -[X in _ = X]addR_opp oppRK.
    rewrite -mulRDr [X in _ = X]mulRC.
    have Hzn0 : z != 0 by apply /eqP /gtR_eqF /ltR_leR_trans; [exact H0x| exact Hxz].
    have H1zn0 : 1 - z != 0 by apply /eqP; move => /subR0_eq /gtR_eqF H; apply /H /leR_ltR_trans; [exact Hzy| exact Hy1].
    have Hzn0' : z <> 0 by move : Hzn0 => /eqP.
    have H1zn0' : 1 - z <> 0 by move : H1zn0 => /eqP.
    have Hz1zn0 : z * (1 - z) <> 0 by rewrite mulR_neq0.
    have ln2n0 : ln 2 <> 0 by move : ln2_gt0 => /gtR_eqF.
    have -> : / z = (1 - z) / (z * (1 - z)) by change (/ z = (1 - z) * / (z * (1 - z))); rewrite invRM // [X in _ = _ * X]mulRC mulRA mulRV // mul1R.
    have -> : / (1 - z) = z  / (z * (1 - z)) by change (/ (1 - z) = z * / (z * (1 - z))); rewrite invRM // mulRA mulRV // mul1R.
    rewrite -Rdiv_plus_distr.
    rewrite -addRA Rplus_opp_l addR0.
    by rewrite div1R -invRM.
  -
    move => z [Hxz Hzy].
    have Hz : 0 < z by apply /ltR_leR_trans; [exact H0x| exact Hxz].
    have H1z : 0 < 1 - z by apply /subR_gt0 /leR_ltR_trans; [exact Hzy| exact Hy1].
    apply /or_introl /invR_gt0.
    by apply mulR_gt0; [apply mulR_gt0|apply ln2_gt0].
Qed.

Lemma concavity_of_entropy : concavef_in open_unit_interval H2.
Proof.
rewrite /concavef_in /concavef_leq => x y t Hx Hy Ht.
(* wlogつかう. まず関係ない変数を戻し, *)
move : t Ht.
(* 不等号をorでつないだやつを用意して *)
move : (Rtotal_order x y) => Hxy.
(* その不等号のひとつを固定してwlogする *)
wlog : x y Hx Hy Hxy / x < y.
  move => H.
  case Hxy; [apply H|] => //.
  case => [-> t Ht|]; [exact/convexf_leqxx|].
  move => Hxy'; apply convexf_leq_sym.
  apply H => //.
  by apply or_introl.
by move => Hxy' t Ht; apply concavity_of_entropy_x_le_y.
Qed.

End entropy_concave_alternative_proof_binary_case.

Require Import chap2.

Section mutual_information_concave.

Variables (A B : finType) (Q : A -> dist B).
Hypothesis B_not_empty : (0 < #|B|)%nat.

(* If Cond is statisfied, then the conditional probability is indeed Q *)
(*Lemma Cond_cproba (d : dist A) :
  forall a b, d a <> 0 ->
    \Pr_(Swap.d (ProdDist.d d Q))[[set b]|[set a]] = Q a b.
Proof.
move=> a b /eqP Hda.
rewrite (@channel.channel_cPr _ _ Q d a b Hda); congr cPr.
apply/dist_ext => -[b0 a0].
by rewrite !Swap.dE channel.JointDistChan.dE ProdDist.dE.
Qed.*)

Lemma mutual_information_concave :
  concave_dist (fun P => MutualInfo.mi (CDist.make_joint P Q)).
Proof.
suff : concave_dist (fun P => let PQ := Swap.d (CDist.make_joint P Q) in
                           `H (Bivar.fst PQ) - CondEntropy.h PQ).
  set f := fun _ => _. set g := fun _ => _.
  rewrite (FunctionalExtensionality.functional_extensionality f g) //.
  move=> d; rewrite {}/f {}/g /=.
  by rewrite -MutualInfo.miE2 -mi_sym.
apply concave_distB.
- move: (entropy_concave B_not_empty) => H.
  move=> p q t t01 /=.
  rewrite 3!Swap.fst.
  apply: leR_trans (H (Bivar.snd (CDist.make_joint p Q)) (Bivar.snd (CDist.make_joint q Q)) t t01).
  rewrite -ProdDist.snd_convex; exact/leRR.
- suff : affine_dist (fun x => CondEntropy.h (Swap.d (CDist.make_joint x Q))) by case.
  apply/affine_distP => p q t t01 /=.
  rewrite /CondEntropy.h /CondEntropy.h1.
  rewrite 2!big_distrr /= -big_split /=; apply eq_bigr => a _.
  rewrite !Swap.snd !Bivar.fstE !mulRN -oppRD; congr (- _).
  rewrite !big_distrr -big_split /=; apply eq_bigr => b _.
  rewrite !big_distrl !big_distrr -big_split /=; apply eq_bigr => b0 _.
  rewrite !ProdDist.dE /= ConvexDist.dE /=.
  rewrite !(mulRA t) !(mulRA t.~).
  case/boolP: (t * p a == 0) => /eqP Hp.
    rewrite Hp.
    case/boolP: (t.~ * q a == 0) => /eqP Hq.
      rewrite Hq; field.
    rewrite !(mul0R,add0R).
    rewrite -CDist.E /=; last by rewrite ConvexDist.dE Hp add0R.
    rewrite -CDist.E /= //; by move: Hq; rewrite mulR_neq0 => -[].
  case/boolP: (t.~ * q a == 0) => /eqP Hq.
    rewrite Hq !(mul0R,addR0).
    rewrite -CDist.E; last by rewrite ConvexDist.dE Hq addR0.
    rewrite -CDist.E /= //; by move: Hp; rewrite mulR_neq0 => -[].
  rewrite -CDist.E; last first.
    rewrite /= ConvexDist.dE paddR_eq0; [tauto | |].
    apply/mulR_ge0; [by case: t01 | exact/dist_ge0].
    apply/mulR_ge0; [apply/onem_ge0; by case: t01 | exact/dist_ge0].
  rewrite -CDist.E; last by move: Hp; rewrite mulR_neq0 => -[].
  rewrite -CDist.E //=; last by move: Hq; rewrite mulR_neq0 => -[].
  field.
Qed.

End mutual_information_concave.

Section mutual_information_convex.

Variables (A B : finType) (P : dist A).

Let Cond (d : {dist B * A}) := \rsum_(ab in {: A * B}) P ab.1 * d (swap ab) = 1.

Fail Lemma mutual_information_convex :
  pconvex_dist
    (fun (Q : {dist B * A}) (H : Cond Q) => MutualInfo.mi (DepProdDist.d H)).

End mutual_information_convex.
