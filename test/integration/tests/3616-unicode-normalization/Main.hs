import StackTest

main :: IO ()
main = do
  stack ["new", "ば日本-4本", "--bare"]
  stack ["build"]
