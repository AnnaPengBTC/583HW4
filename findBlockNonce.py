#!/bin/python
import hashlib
import os
import random
import secrets


def mine_block(k, prev_hash, rand_lines):
    """
        k - Number of trailing zeros in the binary representation (integer)
        prev_hash - the hash of the previous block (bytes)
        rand_lines - a set of "transactions," i.e., data to be included in this block (list of strings)

        Complete this function to find a nonce such that 
        sha256(prev_hash + rand_lines + nonce)
        has k trailing zeros in its *binary* representation
    """
    if not isinstance(k, int) or k < 0:
        print("mine_block expects positive integer")
        return b'\x00'

    # Combine previous hash and transactions into a single string
    combined_str = prev_hash.hex()
    for line in rand_lines:
        combined_str += line

    target = '0' * k

    while True:
        # Generate a random nonce using secrets module
        nonce = secrets.token_bytes(16)
        
        # Encode the combined string with the nonce appended
        nonce_str = combined_str + nonce.hex()
        nonce_bytes = nonce_str.encode('utf-8')

        # Compute the SHA256 hash
        hash_result = hashlib.sha256(nonce_bytes).hexdigest()

        # Convert the hash result to binary
        binary_hash = bin(int(hash_result, 16))[2:].zfill(256)

        # Check if the last k bits are zero
        if binary_hash[-k:] == target:
            assert isinstance(nonce, bytes), 'nonce should be of type bytes'
            break
    return nonce

def get_random_lines(filename, quantity):
    """
    This is a helper function to get the quantity of lines ("transactions")
    as a list from the filename given. 
    Do not modify this function
    """
    lines = []
    with open(filename, 'r') as f:
        for line in f:
            lines.append(line.strip())

    random_lines = []
    for x in range(quantity):
        random_lines.append(lines[random.randint(0, len(lines) - 1)])
    return random_lines

if __name__ == '__main__':
    # This code will be helpful for your testing
    filename = "bitcoin_text.txt"
    num_lines = 10  # The number of "transactions" included in the block

    # The "difficulty" level. For our blocks this is the number of Least Significant Bits
    # that are 0s. For example, if diff = 5 then the last 5 bits of a valid block hash would be zeros
    # The grader will not exceed 20 bits of "difficulty" because larger values take too long
    diff = 20

    rand_lines = get_random_lines(filename, num_lines)
    prev_hash = hashlib.sha256(b'previous block').digest()
    nonce = mine_block(diff, prev_hash, rand_lines)
    print(nonce)
