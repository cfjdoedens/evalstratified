test_that("HHH 0.01", {
  expect_equal(foutloze_posten_equivalent(
    ihr = 'H',
    ibr = 'H',
    car = 'H',
    materialiteit = 0.01
  ),
  0)
})
test_that("HHL 0.01", {
  expect_equal(foutloze_posten_equivalent(
    ihr = 'H',
    ibr = 'H',
    car = 'L',
    materialiteit = 0.01
  ),
  138)
})
test_that("HHL 0.02", {
  expect_equal(foutloze_posten_equivalent(
    ihr = 'H',
    ibr = 'H',
    car = 'L',
    materialiteit = 0.02
  ),
  69)
})
test_that("LLL 0.01", {
  expect_equal(foutloze_posten_equivalent(
    ihr = 'L',
    ibr = 'L',
    car = 'L',
    materialiteit = 0.01
  ),
  293)
})
test_that("LLL 0.01 grotere materialiteit leidt tot veel minder equivalente foutloze steken", {
  expect_equal(foutloze_posten_equivalent(
    ihr = 'L',
    ibr = 'L',
    car = 'L',
    materialiteit = 0.02
  ),
  146)
})
