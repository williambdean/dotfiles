local ls = require "luasnip"
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local ps = ls.parser.parse_snippet

ls.add_snippets("python", {
  ps(
    "random",
    [[
  import numpy as np

  seed = sum(map(ord, "${1:the string to seed the RNG}"))
  rng = np.random.default_rng(seed)

  $0
  ]]
  ),
  ps(
    "common",
    [[
  import polars as pl
  import pandas as pd
  import numpy as np

  import matplotlib.pyplot as plt

  $0
  ]]
  ),
  ps(
    "priorclass",
    [[
  from pymc_extras.prior import Prior

  $0
  ]]
  ),
  ps(
    "pymc-marketing-mmm",
    [[
  from pymc_extras.prior import Prior

  from pymc_marketing.mmm import MMM, $1

  $0
  ]]
  ),
  ps(
    "pt",
    [[
  import pytensor.tensor as pt

  $0
  ]]
  ),
  ps(
    "ptfunction",
    [[
  import pytensor.tensor as pt
  from pytensor import function

  $0
  ]]
  ),
  ps(
    "dataclass",
    [[
  from dataclasses import dataclass

  @dataclass
  class ${1:ClassName}:
      ${2:attribute}: ${3:type} = $0
  ]]
  ),
  ps(
    "pmModel",
    [[
  import pymc as pm

  coords = {$1}
  with pm.Model(coords=coords) as ${2:model}:
      $0
  ]]
  ),
})

ls.add_snippets("lua", {
  ps("M", "local M = {}\n\n$0\n\nreturn M"),
  ps(
    "lf",
    [[
  local ${1:function_name} = function(${2:opts})
    $0
  end
  ]]
  ),
  ps(
    "mf",
    [[
  M.${1:function_name} = function(${2:opts})
    $0
  end
  ]]
  ),
  ps(
    "gh",
    [[
  local gh = require "octo.gh"

  $0
  ]]
  ),
})
