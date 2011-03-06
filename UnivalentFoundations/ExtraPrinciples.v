(** Statements of special principles, such as Function Extensionality and Univalence Axioms,
   together with proofs about their relations. *)

Require Import HomotopyDefinitions WeakEquivalence.

Definition univalence_statement := forall U V, is_wequiv (@path_to_weq U V).

Definition eta {A B} (f : A -> B) := fun x => f x.

Definition eta_rule_statement := forall A B (f : A -> B), eta f ~~> f.

Definition function_extensionality_statement := forall A B (f g : A -> B), (forall x, f x ~~> g x) -> f ~~> g.

Section UnivalenceImpliesFunctionExtensionality.

  (** * Univalence and Eta rule Imply Function Extensionality *)

  Hypothesis univalence : univalence_statement.
  Hypothesis eta_axiom : forall {A B} (h : A -> B), eta h ~~> h.

  (** The axioms allows us to go in the other direction: every weak equivalence yields a path. *)

  Definition weq_to_path {U V} : wequiv U V -> U ~~> V.
  Proof.
    apply weq_inv.
    exists (@path_to_weq U V).
    apply univalence.
  Defined.

  (** The map [weq_to_path] is a section of [path_to_weq]. *)

  Lemma weq_to_path_section U V : forall (w : wequiv U V), path_to_weq (weq_to_path w) ~~> w.
  Proof.
    intro w.
    exact (weq_inv_is_section _ _ (existT _ (@path_to_weq U V) (univalence U V)) w).
  Defined.

  (** We can do better than [weq_to_path], we can turn a fibration fibered by weak
   equivalences to one fiberered over paths. *)

  Definition pred_weq_to_path U V : (wequiv U V -> Type) -> (U ~~> V -> Type).
  Proof.
    intros Q p.
    apply Q.
    apply path_to_weq.
    exact p.
  Defined.

  (** The following theorem is of central importance. Just like there is an induction
   principle for paths, there is a corresponding one for weak equivalences. In the proof
   we use [pred_weq_to_path] to transport the predicate [P] of weak equivalences to a
   predicate [P'] on paths. Then we use path induction and transport back to [P]. *)

  Theorem weq_induction (P : forall U V, wequiv U V -> Type) :
    (forall T, P T T (idweq T)) -> (forall U V (w : wequiv U V), P U V w).
  Proof.
    intro r.
    pose (P' := (fun U V => pred_weq_to_path U V (P U V))).
    assert (r' : forall T : Type, P' T T (idpath T)).
    intro T.
    exact (r T).
    intros U V w.
    apply (transport (weq_to_path_section _ _ w)).
    exact (paths_rect _ P' r' U V (weq_to_path w)).
  Defined.

  (** We should strive to make the following lemma shorter. The lemma states that a map
     which is pointwise homotopic to the identity is a weak equivalence. *)

  Lemma weq_pointwise_idmap A (f : A -> A) : (forall x, f x ~~> x) -> is_wequiv f.
  Proof.
    intros p y.
    contract_hfiber y (p y).
    apply total_paths with (p := ! (p z) @ q).
    simpl.
    eapply concat.
    apply transport_hfiber.
    path_via (map f (!q @ p z) @ q).
    path_via (map f (! (!p z @ q))).
    eapply concat.
    path_tricks.
    path_tricks.
    path_via ((map f (!q) @ map f (p z)) @ q).
    path_via (map f (!q) @ (map f (p z) @ q)).
    apply concat_associativity.
    path_via (map f (!q) @ (map f q @ p y)).
    apply map_action.
    path_via ((map f (!q) @ map f q) @ p y).
    apply opposite; apply concat_associativity.
    path_via (idpath (f y) @ p y).
    path_via (! map f q @ map f q).
  Defined.

  (** The eta axiom essentially states that [eta] is a weak equivalence. *)

  Theorem etaweq A B : wequiv (A -> B) (A -> B).
  Proof.
    exists (@eta A B).
    apply weq_pointwise_idmap.
    apply eta_axiom.
  Defined.

  (** Another important ingridient in the proof of extensionality is the fact that
     exponentiation preserves weak equivalences, i.e., if [w] is a weak equivalence
     then post-composition by [w] is again a weak equivalence. *)

  Theorem weq_exponential : forall {A B} (w : wequiv A B) C, wequiv (C -> A) (C -> B).
  Proof.
    intros A B w C.
    exists (fun h => w o h).
    generalize A B w.
    apply weq_induction.
    intro D.
    apply (projT2 (etaweq C D)).
  Defined.

  (** We are almost ready to prove extensionality, but first we need to show that the source
     and target maps from the total space of maps are weak equivalences. *)

  Definition path_space A := {xy : A * A & fst xy ~~> snd xy}.

  Definition src A : wequiv (path_space A) A.
  Proof.
    exists (fun p => fst (projT1 p)).
    intros x.
    eexists (existT _ (existT (fun (xy : A * A) => fst xy ~~> snd xy) (x,x) (idpath x)) _).
    intros [[[u v] p] q].
    simpl in * |- *.
    induction q as [a].
    induction p as [b].
    apply idpath.
  Defined.

  Definition trg A : wequiv (path_space A) A.
  Proof.
    exists (fun p => snd (projT1 p)).
    intros x.
    eexists (existT _ (existT (fun (xy : A * A) => fst xy ~~> snd xy) (x,x) (idpath x)) _).
    intros [[[u v] p] q].
    simpl in * |- *.
    induction q as [a].
    induction p as [b].
    apply idpath.
  Defined.

  (** And finally, we are ready to prove that extensionality of maps holds, i.e., if two
     maps are pointwise homotopic then they are homotopic. First we outline the proof.
     
     Suppose maps [f g : A -> B] are extensionally equal via a pointwise homotopy [p]. We
     seek a path [f ~~> g]. Because [eta f ~~> f] and [eta g ~~> g] it suffices to find
     a path [eta f ~~> eta g].
     
     Consider the maps [d e : S -> path_space T] where [d x = existT _ (f x, f x) (idpath
     x)] and [e x = existT _ (f x, g x) (p x)]. If we compose [d] and [e] with [trg] we get
     [eta f] and [eta g], respectively. So, if we had a path from [d] to [e], we would get
     one from [eta f] to [eta g]. But we can get a path from [d] to [e] because
     [src o d = eta f = src o e] and composition with [src] is an equivalence.
   *)

  Theorem extensionality {A B : Set} (f g : A -> B) : (forall x, f x ~~> g x) -> (f ~~> g).
  Proof.
    intro p.
    pose (d := fun x : A => existT (fun xy => fst xy ~~> snd xy) (f x, f x) (idpath (f x))).
    pose (e := fun x : A => existT (fun xy => fst xy ~~> snd xy) (f x, g x) (p x)).
    pose (src_compose := weq_exponential (src B) A).
    pose (trg_compose := weq_exponential (trg B) A).
    apply weq_injective with (w := etaweq A B).
    simpl.
    path_via (projT1 trg_compose e).
    path_via (projT1 trg_compose d).
    apply map.
    apply weq_injective with (w := src_compose).
    apply idpath.
  Defined.

End UnivalenceImpliesFunctionExtensionality.
