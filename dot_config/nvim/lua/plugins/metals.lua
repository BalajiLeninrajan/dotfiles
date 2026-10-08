-- The lang.scala extra attaches Metals to java too, which fights jdtls over inlay hints.
return {
  { "scalameta/nvim-metals", ft = { "scala", "sbt" } },
}
