{-# LANGUAGE MonoLocalBinds #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE ViewPatterns #-}

module Constrained.API (
  Logic (..),
  Semantics (..),
  Syntax (..),
  Foldy (..),
  NumSpec (..),
  MaybeBounded (..),
  NonEmpty ((:|)),
  Specification (..),
  Term (..),
  Fun (..),
  name,
  named,
  Pred (..),
  Literal,
  HasSpec (..),
  HasSimpleRep (..),
  OrdLike (..),
  conformsToSpecE,
  conformsToSpec,
  satisfies,
  genFromSpecT,
  genFromSpec,
  debugSpec,
  genFromSpecWithSeed,
  simplifySpec,
  cardinality,
  ifElse,
  whenTrue,
  simplifyTerm,
  constrained,
  assertExplain,
  assert,
  forAll,
  exists,
  unsafeExists,
  letBind,
  reify,
  assertReified,
  explanation,
  monitor,
  reifies,
  dependsOn,
  lit,
  genHint,
  giveHint,
  (<.),
  (<=.),
  (>=.),
  (>.),
  (==.),
  (/=.),
  not_,
  or_,
  (||.),
  toGeneric_,
  fromGeneric_,
  (+.),
  (-.),
  negate_,
  addFn,
  negateFn,
  Numeric,
  pair_,
  fst_,
  snd_,
  prodSnd_,
  prodFst_,
  prod_,
  IsNormalType,
  injLeft_,
  injRight_,
  left_,
  right_,
  cJust_,
  cNothing_,
  caseOn,
  branch,
  branchW,
  forAll',
  constrained',
  reify',
  con,
  onCon,
  isCon,
  sel,
  match,
  onJust,
  isJust,
  chooseSpec,
  equalSpec,
  notEqualSpec,
  notMemberSpec,
  id_,
  flip_,
  compose_,
  foldMap_,
  sum_,
  elem_,
  singletonList_,
  append_,
  (++.),
  sizeOf,
  sizeOf_,
  null_,
  hasSize,
  rangeSize,
  length_,
  genFromSizeSpec,
  between,
  maxSpec,
  SetW (..),
  SetSpec (..),
  singleton_,
  member_,
  union_,
  subset_,
  disjoint_,
  fromList_,
  pattern Elem,
  pattern ToGeneric,
  pattern FromGeneric,
  printPlan,
  NumLike,
  PairSpec (..),
  MapSpec (..),
  dom_,
  rng_,
  lookup_,
  fstSpec,
  sndSpec,
  var,
  Prod (..),
)
where

import Constrained.Base (
  Fun (..),
  HasSpec (..),
  Literal,
  Logic (..),
  Pred (..),
  Semantics (..),
  Specification (..),
  Syntax (..),
  Term (..),
  constrained,
  equalSpec,
  fromGeneric_,
  giveHint,
  name,
  named,
  notEqualSpec,
  notMemberSpec,
  toGeneric_,
  pattern FromGeneric,
  pattern ToGeneric,
 )
import Constrained.Conformance (
  conformsToSpec,
  conformsToSpecE,
  satisfies,
 )
import Constrained.Core (NonEmpty ((:|)))
import Constrained.Generic (HasSimpleRep (..), Prod (..))
import Constrained.NumSpec (
  MaybeBounded (..),
  NumLike,
  NumSpec (..),
  Numeric,
  OrdLike (..),
  addFn,
  cardinality,
  negateFn,
 )

import Constrained.Spec.SumProd
import Constrained.TheKnot

import Constrained.Syntax (
  assert,
  assertExplain,
  assertReified,
  dependsOn,
  exists,
  explanation,
  forAll,
  genHint,
  letBind,
  lit,
  monitor,
  reifies,
  reify,
  unsafeExists,
 )

import Constrained.Spec.Map (
  MapSpec (..),
  dom_,
  fstSpec,
  lookup_,
  rng_,
  sndSpec,
 )
import Constrained.Spec.Set (
  SetSpec (..),
  SetW (..),
  disjoint_,
  fromList_,
  member_,
  singleton_,
  subset_,
  union_,
 )
import Constrained.Syntax (var)

infix 4 /=.
(/=.) :: HasSpec a => Term a -> Term a -> Term Bool
a /=. b = not_ (a ==. b)

length_ :: HasSpec a => Term [a] -> Term Integer
length_ = sizeOf_

infixr 2 ||.
(||.) ::
  Term Bool ->
  Term Bool ->
  Term Bool
(||.) = or_

infixr 5 ++.
(++.) :: HasSpec a => Term [a] -> Term [a] -> Term [a]
(++.) = append_

null_ :: (HasSpec a, Sized a) => Term a -> Term Bool
null_ xs = sizeOf_ xs ==. 0
