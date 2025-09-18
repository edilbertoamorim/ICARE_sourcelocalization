from setuptools import setup, find_packages

requirements = [
    'numpy',
    'scikit-learn',
]

setup(
    name='distributed_SLSH',
    description='',
    packages=['middleware', 'worker_node'],
    install_requires=requirements,
)
