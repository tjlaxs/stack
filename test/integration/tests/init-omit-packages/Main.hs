import Control.Monad (unless)
import StackTest
import System.IO (readFile)

main :: IO ()
main = do
  removeFileIgnore "stack.yaml"
  stackErr ["init", "--resolver", "lts-11.22"]
  stack ["init", "--resolver", "lts-11.22", "--omit-packages"]
  contents <- lines <$> readFile "stack.yaml"
  unless ("#- bad" `elem` contents) $
    error "commented out 'bad' package was expected"
