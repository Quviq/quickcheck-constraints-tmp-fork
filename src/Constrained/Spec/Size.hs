{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE CPP #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeOperators #-}
-- Not sure why (Logic "sizeOf_" SizeW '[t] Integer) is an orphan instance
-- 'data SizeW', is defined in the same file as the instance.
{-# OPTIONS_GHC -Wno-orphans #-}

-- The pattern completeness checker is much weaker before ghc-9.0. Rather than introducing redundant
-- cases and turning off the overlap check in newer ghc versions we disable the check for old
-- versions.
#if __GLASGOW_HASKELL__ < 900
{-# OPTIONS_GHC -Wno-incomplete-patterns #-}
#endif

module Constrained.Spec.Size where

import Constrained.Base
import Constrained.Conformance (satisfies)
import Constrained.GenT
import Constrained.Generic
import Constrained.NumSpec
import Constrained.Syntax
import Constrained.TheKnot (genFromSpecT, (<=.), (==.))
import Constrained.List
import Data.List.NonEmpty (NonEmpty)
import qualified Data.List.NonEmpty as NE
import Data.Kind

-- ======================================================================
-- Size and its 'generic' operations over Sized types.
-- ======================================================================

-- | Because Sizes should always be >= 0, We provide this alternate generator
--   that can be used to replace (genFromSpecT @Integer), to ensure this important property
genFromSizeSpec :: MonadGenError m => Specification Integer -> GenT m Integer
genFromSizeSpec integerSpec = genFromSpecT (integerSpec <> geqSpec 0)

data SizeW (dom :: [Type]) rng :: Type where
  SizeOfW :: (Sized n, HasSpec n) => SizeW '[n] Integer

deriving instance Eq (SizeW ds r)

instance Show (SizeW d r) where
  show SizeOfW = "sizeOf_"

instance Semantics SizeW where
  semantics SizeOfW = sizeOf -- From the Sized class.

instance Syntax SizeW

instance Logic SizeW where
  propagate f ctxt (ExplainSpec [] s) = propagate f ctxt s
  propagate f ctxt (ExplainSpec es s) = ExplainSpec es $ propagate f ctxt s
  propagate _ _ TrueSpec = TrueSpec
  propagate _ _ (ErrorSpec msgs) = ErrorSpec msgs
  propagate SizeOfW (NilCtx HOLE) (SuspendedSpec v ps) = constrained $ \v' -> Let (App SizeOfW (v' :> Nil)) (v :-> ps)
  propagate SizeOfW (NilCtx HOLE) (TypeSpec ts cant) = liftSizeSpec ts cant
  propagate SizeOfW (NilCtx HOLE) (MemberSpec es) = liftMemberSpec (NE.toList es)

  mapTypeSpec (SizeOfW :: SizeW '[a] b) ts =
    constrained $ \x ->
      unsafeExists $ \x' -> Assert (x ==. sizeOf_ x') <> toPreds @a x' ts

sizeOfFn :: forall a. (HasSpec a, Sized a) => Fun '[a] Integer
sizeOfFn = Fun SizeOfW

sizeOf_ :: (HasSpec t, Sized t) => Term t -> Term Integer
sizeOf_ = appTerm SizeOfW

-- ======================================

rangeSize :: Integer -> Integer -> SizeSpec
rangeSize a b | a < 0 || b < 0 = error ("Negative Int in call to rangeSize: " ++ show a ++ " " ++ show b)
rangeSize a b = NumSpecInterval (Just a) (Just b)

between :: (HasSpec a, TypeSpec a ~ NumSpec a) => a -> a -> Specification a
between lo hi = TypeSpec (NumSpecInterval (Just lo) (Just hi)) []

-- | The widest interval whose largest element is admitted by the original spec
maxSpec :: Specification Integer -> Specification Integer
maxSpec (ExplainSpec es s) = explainSpecOpt es (maxSpec s)
maxSpec TrueSpec = TrueSpec
maxSpec s@(SuspendedSpec _ _) =
  constrained $ \x -> unsafeExists $ \y -> [y `satisfies` s, Explain (pure "maxSpec on SuspendedSpec") $ Assert (x <=. y)]
maxSpec (ErrorSpec xs) = ErrorSpec xs
maxSpec (MemberSpec xs) = leqSpec (maximum xs)
maxSpec (TypeSpec (NumSpecInterval _ hi) bad) = TypeSpec (NumSpecInterval Nothing hi) bad

-- ================
-- Sized
-- ================

type SizeSpec = NumSpec Integer

class Sized t where
  sizeOf :: t -> Integer
  default sizeOf :: (HasSimpleRep t, Sized (SimpleRep t)) => t -> Integer
  sizeOf = sizeOf . toSimpleRep

  liftSizeSpec :: HasSpec t => SizeSpec -> [Integer] -> Specification t
  default liftSizeSpec ::
    ( HasSpec t
    , HasSimpleRep t
    , Sized (SimpleRep t)
    , HasSpec (SimpleRep t)
    , TypeSpec t ~ TypeSpec (SimpleRep t)
    ) =>
    SizeSpec -> [Integer] -> Specification t
  liftSizeSpec sz cant = fromSimpleRepSpec $ liftSizeSpec sz cant

  liftMemberSpec :: HasSpec t => [Integer] -> Specification t
  default liftMemberSpec ::
    ( HasSpec t
    , HasSpec (SimpleRep t)
    , HasSimpleRep t
    , Sized (SimpleRep t)
    , TypeSpec t ~ TypeSpec (SimpleRep t)
    ) =>
    [Integer] -> Specification t
  liftMemberSpec = fromSimpleRepSpec . liftMemberSpec

  sizeOfTypeSpec :: HasSpec t => TypeSpec t -> Specification Integer
  default sizeOfTypeSpec ::
    ( HasSpec (SimpleRep t)
    , Sized (SimpleRep t)
    , TypeSpec t ~ TypeSpec (SimpleRep t)
    ) =>
    TypeSpec t -> Specification Integer
  sizeOfTypeSpec = sizeOfTypeSpec @(SimpleRep t)

-- How to constrain the size of any type, with a Sized instance
hasSize :: (HasSpec t, Sized t) => SizeSpec -> Specification t
hasSize sz = liftSizeSpec sz []
